:- begin_tests(sudoku_constraints).

:- use_module('../../src/prolog/sudoku').
:- use_module('../../src/prolog/puzzle_io').
:- use_module(library(clpfd)).


test(accepts_valid_puzzle) :-
    easy_puzzle(Puzzle),
    valid_puzzle(Puzzle).


test(accepts_valid_but_unsolvable_puzzle) :-
    unsolvable_puzzle(Puzzle),
    valid_puzzle(Puzzle).


test(rejects_wrong_row_count, [fail]) :-
    zero_rows(8, Puzzle),
    valid_puzzle(Puzzle).


test(rejects_wrong_column_count, [fail]) :-
    zero_rows(8, RemainingRows),
    valid_puzzle([[0, 0, 0, 0, 0, 0, 0, 0]|RemainingRows]).


test(rejects_non_integer, [fail]) :-
    zero_rows(8, RemainingRows),
    valid_puzzle([[x, 0, 0, 0, 0, 0, 0, 0, 0]|RemainingRows]).


test(rejects_out_of_range_value, [fail]) :-
    zero_rows(8, RemainingRows),
    valid_puzzle([[10, 0, 0, 0, 0, 0, 0, 0, 0]|RemainingRows]).


test(rejects_duplicate_row_clue, [fail]) :-
    zero_rows(8, RemainingRows),
    valid_puzzle([[1, 0, 0, 0, 0, 0, 0, 0, 1]|RemainingRows]).


test(rejects_duplicate_column_clue, [fail]) :-
    zero_rows(7, MiddleRows),
    ClueRow = [1, 0, 0, 0, 0, 0, 0, 0, 0],
    append([ClueRow|MiddleRows], [ClueRow], Puzzle),
    valid_puzzle(Puzzle).


test(rejects_duplicate_box_clue, [fail]) :-
    zero_rows(7, RemainingRows),
    Puzzle = [
        [1, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 1, 0, 0, 0, 0, 0, 0, 0]
        | RemainingRows
    ],
    valid_puzzle(Puzzle).


test(zeros_become_distinct_finite_domain_variables) :-
    zero_rows(9, Puzzle),
    sudoku:constrain_puzzle(Puzzle, Board),
    Board = [[First, Second|_]|_],
    var(First),
    var(Second),
    First \== Second,
    fd_dom(First, 1..9),
    fd_dom(Second, 1..9).


test(fixed_clues_are_preserved) :-
    easy_puzzle(Puzzle),
    sudoku:constrain_puzzle(Puzzle, Board),
    Board = [[5, 3, _, _, 7, _, _, _, _]|_].


test(row_constraint_is_posted, [fail]) :-
    zero_rows(9, Puzzle),
    sudoku:constrain_puzzle(Puzzle, Board),
    Board = [[First, Second|_]|_],
    First #= 1,
    Second #= 1.


test(column_constraint_is_posted, [fail]) :-
    zero_rows(9, Puzzle),
    sudoku:constrain_puzzle(Puzzle, Board),
    Board = [FirstRow, SecondRow|_],
    FirstRow = [First|_],
    SecondRow = [Second|_],
    First #= 1,
    Second #= 1.


test(box_constraint_is_posted, [fail]) :-
    zero_rows(9, Puzzle),
    sudoku:constrain_puzzle(Puzzle, Board),
    Board = [FirstRow, SecondRow|_],
    FirstRow = [First|_],
    SecondRow = [_, Second|_],
    First #= 1,
    Second #= 1.


test(solves_easy_fixture) :-
    easy_puzzle(Puzzle),
    once(solve(Puzzle, Solution)),
    solved_puzzle(Expected),
    assertion(Solution == Expected),
    assertion(valid_solution(Puzzle, Solution)).


test(solves_hard_fixture) :-
    fixture(hard, Puzzle),
    once(solve(Puzzle, Solution)),
    assertion(valid_solution(Puzzle, Solution)).


test(accepts_completed_fixture) :-
    solved_puzzle(Puzzle),
    once(solve(Puzzle, Solution)),
    assertion(Solution == Puzzle),
    assertion(valid_solution(Puzzle, Solution)).


test(valid_but_unsolvable_fails, [fail]) :-
    unsolvable_puzzle(Puzzle),
    solve(Puzzle, _).


test(rejects_all_invalid_fixtures) :-
    forall(
        member(Name, [
            'invalid/wrong_rows',
            'invalid/wrong_columns',
            'invalid/non_integer',
            'invalid/out_of_range',
            'invalid/duplicate_row',
            'invalid/duplicate_column',
            'invalid/duplicate_box'
        ]),
        (   fixture(Name, Puzzle),
            assertion(\+ valid_puzzle(Puzzle)),
            assertion(\+ solve(Puzzle, _))
        )
    ).


test(solution_rejects_incomplete_board, [fail]) :-
    easy_puzzle(Puzzle),
    valid_solution(Puzzle, Puzzle).


test(solution_rejects_duplicate_row, [fail]) :-
    zero_rows(9, Puzzle),
    solved_puzzle([[_, Second|Rest]|OtherRows]),
    Invalid = [[Second, Second|Rest]|OtherRows],
    valid_solution(Puzzle, Invalid).


test(solution_rejects_duplicate_column, [fail]) :-
    zero_rows(9, Puzzle),
    solved_puzzle([[First, Second|Rest]|OtherRows]),
    Invalid = [[Second, First|Rest]|OtherRows],
    valid_solution(Puzzle, Invalid).


test(solution_rejects_invalid_box, [fail]) :-
    zero_rows(9, Puzzle),
    solved_puzzle([First, Second, Third, Fourth|OtherRows]),
    Invalid = [First, Fourth, Third, Second|OtherRows],
    valid_solution(Puzzle, Invalid).


test(solution_rejects_changed_clue, [fail]) :-
    solved_puzzle(Puzzle),
    maplist(swap_row_digits, Puzzle, OtherSolution),
    valid_solution(Puzzle, OtherSolution).


test(solution_rejects_wrong_shape, [fail]) :-
    solved_puzzle(Puzzle),
    Puzzle = [_|ShortSolution],
    valid_solution(Puzzle, ShortSolution).


test(solution_rejects_noninteger, [fail]) :-
    zero_rows(9, Puzzle),
    solved_puzzle([[_, Second|Rest]|OtherRows]),
    Invalid = [[x, Second|Rest]|OtherRows],
    valid_solution(Puzzle, Invalid).


swap_row_digits(Row, Swapped) :-
    maplist(swap_digit, Row, Swapped).


swap_digit(3, 5).
swap_digit(5, 3).
swap_digit(Digit, Digit) :-
    Digit =\= 3,
    Digit =\= 5.


fixture(Name, Puzzle) :-
    format(atom(File), 'data/puzzles/~w.txt', [Name]),
    load_puzzle(File, Puzzle).


zero_rows(Count, Rows) :-
    length(Rows, Count),
    maplist(zero_row, Rows).


zero_row([0, 0, 0, 0, 0, 0, 0, 0, 0]).


easy_puzzle(Puzzle) :-
    fixture(easy, Puzzle).


solved_puzzle(Puzzle) :-
    fixture(solved, Puzzle).


unsolvable_puzzle(Puzzle) :-
    fixture(unsolvable, Puzzle).


:- end_tests(sudoku_constraints).
