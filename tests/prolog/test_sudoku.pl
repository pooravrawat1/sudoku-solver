:- begin_tests(sudoku_constraints).

:- use_module('../../src/prolog/sudoku').
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


zero_rows(Count, Rows) :-
    length(Rows, Count),
    maplist(zero_row, Rows).


zero_row([0, 0, 0, 0, 0, 0, 0, 0, 0]).


easy_puzzle([
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9]
]).


unsolvable_puzzle([
    [5, 3, 1, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9]
]).


:- end_tests(sudoku_constraints).
