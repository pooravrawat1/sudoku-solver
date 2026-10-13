:- module(sudoku_trace,
    [ trace_puzzle/1
    ]).

:- use_module(library(clpfd)).
:- use_module(library(http/json)).
:- use_module(sudoku).

:- multifile user:prolog_trace_interception/4.


% The debugger hook is active only while trace_labeling/2 runs. System access
% exposes CLP(FD)'s actual choice rule, including its redo port.
user:prolog_trace_interception(Port, Frame, _Choice, continue) :-
    (   (Port == call ; Port = redo(_)),
        prolog_frame_attribute(Frame, goal, Goal),
        Goal = clpfd:choice_order_variable(step, up, Var, _, _, ffc, _),
        nb_current(trace_cells, Cells),
        nth0(Index, Cells, Cell),
        Cell == Var
    ->  sudoku_trace:choice_event(Port, Index, Var)
    ;   true
    ).


%!  trace_puzzle(+Puzzle) is det.
%
%   Writes newline-delimited JSON for one real CLP(FD) execution. Constraint
%   snapshots expose domains. The debugger hook reports native labeling
%   choices and their redo ports; frozen observers report bindings and undo.
%   Instrumentation does not choose values or prune search.
%   Throws trace_limit after 20000 events. Intended for an isolated process.

trace_puzzle(Puzzle) :-
    nb_setval(trace_count, 0),
    emit(_{type:rule, rule:"sudoku:valid_puzzle/1",
           message:"Check shape, digit range, and conflicting clues."}),
    (   valid_puzzle(Puzzle)
    ->  (   once(trace_solution(Puzzle, Solution))
        ->  emit(_{type:solved, rule:"sudoku:valid_solution/2", board:Solution,
                   message:"Solution verified: all units and original clues are valid."})
        ;   emit(_{type:unsolvable, rule:"clpfd:labeling/2", board:Puzzle,
                   message:"labeling([ffc]) exhausted every branch; no solution satisfies the clues."})
        )
    ;   emit(_{type:invalid, rule:"sudoku:valid_puzzle/1",
               message:"valid_puzzle/1 failed: use nine rows of digits 0–9 with no conflicting clues."})
    ).


trace_solution(Puzzle, Board) :-
    % Reuse the core model's normalization, box layout, and search options.
    sudoku:zeros_to_variables(Puzzle, Board),
    emit(_{type:rule, rule:"sudoku:zeros_to_variables/2",
           message:"Completed normalization: each zero is a fresh logic variable; clues stay fixed."}),
    append(Board, Cells),
    Cells ins 1..9,
    snapshot(Board, "domains", "clpfd:ins/2",
             "After Cells ins 1..9, every unknown has a finite domain."),
    post_units(Board, Board, row, 1),
    transpose(Board, Columns),
    post_units(Columns, Board, column, 1),
    sudoku:puzzle_boxes(Board, Boxes),
    post_units(Boxes, Board, box, 1),
    snapshot(Board, "search", "clpfd:labeling/2",
             "Next: labeling([ffc], Cells), after all 27 all_distinct/1 rules."),
    observe_cells(Cells, 0),
    sudoku:labeling_options(Options),
    trace_labeling(Options, Cells),
    valid_solution(Puzzle, Board).


post_units([], _, _, _).
post_units([Unit|Units], Board, Kind, Index) :-
    format(string(Message), 'Completed all_distinct/1 on ~w ~d; domains shown after propagation.',
           [Kind, Index]),
    all_distinct(Unit),
    snapshot(Board, "constraint", "clpfd:all_distinct/1", Message),
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
    emit(_{type:bind, rule:"clpfd:labeling/2", cell:Index, value:Value}),
    (   true
    ;   emit(_{type:backtrack, rule:"clpfd:labeling/2", cell:Index, value:0}),
        fail
    ).


%!  trace_labeling(+Options, +Cells) is nondet.
%
%   Runs native labeling with the debugger hook enabled. The isolated trace
%   process exposes CLP(FD)'s choice_order_variable/7 call and redo ports.

trace_labeling(Options, Cells) :-
    setup_call_cleanup(
        start_labeling_trace(Cells),
        labeling(Options, Cells),
        stop_labeling_trace
    ).


start_labeling_trace(Cells) :-
    nb_linkval(trace_cells, Cells),
    current_prolog_flag(access_level, Access),
    nb_setval(trace_access_level, Access),
    set_prolog_flag(access_level, system),
    visible(-all),
    visible(+call),
    visible(+redo),
    leash(-all),
    trace.


stop_labeling_trace :-
    notrace,
    nb_delete(trace_cells),
    nb_getval(trace_access_level, Access),
    nb_delete(trace_access_level),
    set_prolog_flag(access_level, Access).


choice_event(Port, Index, Var) :-
    fd_set(Var, Set),
    fdset_to_list(Set, Domain),
    Domain = [First|_],
    Row is Index // 9 + 1,
    Column is Index mod 9 + 1,
    atomics_to_string(Domain, ", ", DomainText),
    (   Port == call
    ->  Type = choice,
        format(string(Message),
               'ffc selects r~dc~d from {~s}; step/up tries ~d first.',
               [Row, Column, DomainText, First])
    ;   Type = retry,
        format(string(Message),
               'redo choice at r~dc~d; exclude ~d and propagate the remaining domain.',
               [Row, Column, First])
    ),
    emit(_{type:Type, rule:"clpfd:choice_order_variable/7",
           cell:Index, domain:Domain, candidate:First, message:Message}).


snapshot(Board, Type, Rule, Message) :-
    maplist(row_domains, Board, Domains),
    emit(_{type:Type, rule:Rule, domains:Domains, message:Message}).


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
