:- module(sudoku_trace,
    [ trace_puzzle/1
    ]).

:- use_module(library(clpfd)).
:- use_module(library(http/json)).
:- use_module(sudoku).


%!  trace_puzzle(+Puzzle) is det.
%
%   Writes newline-delimited JSON for one real CLP(FD) execution. Constraint
%   snapshots expose domains; labeling observers report bindings and their
%   reversal on backtracking. Observers do not choose values or prune search.
%   Throws trace_limit after 20000 events. Intended for an isolated process.

trace_puzzle(Puzzle) :-
    nb_setval(trace_count, 0),
    (   valid_puzzle(Puzzle)
    ->  (   once(trace_solution(Puzzle, Solution))
        ->  emit(_{type:solved, board:Solution,
                   message:"Solution verified: all units and original clues are valid."})
        ;   emit(_{type:unsolvable, board:Puzzle,
                   message:"No solution satisfies all of these clues."})
        )
    ;   emit(_{type:invalid,
               message:"Use nine rows of digits 0–9 with no conflicting clues."})
    ).


trace_solution(Puzzle, Board) :-
    % Reuse the core model's normalization, box layout, and search options.
    sudoku:zeros_to_variables(Puzzle, Board),
    append(Board, Cells),
    Cells ins 1..9,
    snapshot(Board, "domains", "Empty cells become logic variables with domain 1..9."),
    post_units(Board, Board, row, 1),
    transpose(Board, Columns),
    post_units(Columns, Board, column, 1),
    sudoku:puzzle_boxes(Board, Boxes),
    post_units(Boxes, Board, box, 1),
    snapshot(Board, "search", "labeling([ffc], Cells): search any remaining domains."),
    observe_cells(Cells, 0),
    sudoku:labeling_options(Options),
    labeling(Options, Cells),
    valid_solution(Puzzle, Board).


post_units([], _, _, _).
post_units([Unit|Units], Board, Kind, Index) :-
    format(string(Message), 'all_distinct/1 on ~w ~d; propagate remaining domains.',
           [Kind, Index]),
    all_distinct(Unit),
    snapshot(Board, "constraint", Message),
    Next is Index + 1,
    post_units(Units, Board, Kind, Next).


observe_cells([], _).
observe_cells([Cell|Cells], Index) :-
    (   var(Cell)
    ->  freeze(Cell, observe_binding(Index, Cell))
    ;   true
    ),
    Next is Index + 1,
    observe_cells(Cells, Next).


% The failing alternative logs undo when Prolog revisits this binding.
% It introduces no successful alternative and does not implement search.
observe_binding(Index, Value) :-
    emit(_{type:bind, cell:Index, value:Value}),
    (   true
    ;   emit(_{type:backtrack, cell:Index, value:0}),
        fail
    ).


snapshot(Board, Type, Message) :-
    maplist(row_domains, Board, Domains),
    emit(_{type:Type, domains:Domains, message:Message}).


row_domains(Row, Domains) :-
    maplist(cell_domain, Row, Domains).


cell_domain(Cell, Domain) :-
    fd_set(Cell, Set),
    fdset_to_list(Set, Domain).


emit(Event) :-
    nb_getval(trace_count, Count),
    (   Count < 20000
    ->  Next is Count + 1,
        nb_setval(trace_count, Next),
        json_write_dict(current_output, Event, [width(0)]),
        nl
    ;   throw(trace_limit)
    ).
