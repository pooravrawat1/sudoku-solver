:- use_module('../src/prolog/sudoku').
:- use_module('../src/prolog/puzzle_io').

:- initialization(main, main).


%!  main is det.
%
%   Prints solved, unsolvable, or invalid for one named project fixture.

main :-
    current_prolog_flag(argv, Arguments),
    (   Arguments = [Name],
        fixture_file(Name, File)
    ->  load_puzzle(File, Puzzle),
        show_result(Puzzle)
    ;   format(user_error,
            'Usage: swipl -q -s scripts/demo_prolog.pl -- <fixture>~n', []),
        halt(2)
    ).


fixture_file(Name, File) :-
    memberchk(Name, [
        easy,
        hard,
        solved,
        unsolvable,
        'invalid/wrong_rows',
        'invalid/wrong_columns',
        'invalid/non_integer',
        'invalid/out_of_range',
        'invalid/duplicate_row',
        'invalid/duplicate_column',
        'invalid/duplicate_box'
    ]),
    format(atom(File), 'data/puzzles/~w.txt', [Name]).


show_result(Puzzle) :-
    (   valid_puzzle(Puzzle)
    ->  (   once(solve(Puzzle, Solution))
        ->  writeln(solved),
            print_board(Solution)
        ;   writeln(unsolvable)
        )
    ;   writeln(invalid)
    ).
