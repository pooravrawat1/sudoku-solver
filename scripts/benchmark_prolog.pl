:- use_module(library(readutil)).
:- use_module('../src/prolog/sudoku').
:- use_module('../src/prolog/puzzle_io').

:- initialization(main, main).


%!  main is det.
%
%   Serves one timed solver result per fixture name received on standard input.
%   The persistent process keeps interpreter startup outside the measurements.

main :-
    serve_requests.


serve_requests :-
    read_line_to_string(user_input, Name),
    (   Name == end_of_file
    ->  true
    ;   run_fixture(Name),
        serve_requests
    ).


run_fixture(Name) :-
    memberchk(Name, ["easy", "hard"]),
    format(atom(File), 'data/puzzles/~w.txt', [Name]),
    load_puzzle(File, Puzzle),
    get_time(Start),
    (   once(solve(Puzzle, Solution))
    ->  Status = solved
    ;   Status = unsolvable
    ),
    get_time(End),
    Elapsed is End - Start,
    format('~15f~n', [Elapsed]),
    (   Status == solved
    ->  print_board(Solution)
    ;   writeln(unsolvable)
    ),
    flush_output.
