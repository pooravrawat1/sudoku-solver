:- module(sudoku,
    [ valid_puzzle/1
    ]).

:- use_module(library(clpfd)).


%!  valid_puzzle(+Puzzle) is semidet.
%
%   True when Puzzle is a 9 x 9 list of integers in the range 0 through 9
%   and its nonzero clues do not conflict in any row, column, or 3 x 3 box.

valid_puzzle(Puzzle) :-
    is_list(Puzzle),
    length(Puzzle, 9),
    maplist(valid_row, Puzzle),
    clues_are_consistent(Puzzle).


valid_row(Row) :-
    is_list(Row),
    length(Row, 9),
    maplist(valid_cell, Row).


valid_cell(Cell) :-
    integer(Cell),
    between(0, 9, Cell).


clues_are_consistent(Rows) :-
    puzzle_units(Rows, Units),
    maplist(no_duplicate_clues, Units).


puzzle_units(Rows, Units) :-
    transpose(Rows, Columns),
    puzzle_boxes(Rows, Boxes),
    append([Rows, Columns, Boxes], Units).


no_duplicate_clues(Unit) :-
    exclude(=(0), Unit, Clues),
    sort(Clues, UniqueClues),
    same_length(Clues, UniqueClues).


%!  constrain_puzzle(+Puzzle, -Board) is semidet.
%
%   Validates Puzzle, replaces its zeros with fresh logic variables, and
%   posts every Sudoku constraint on Board. It intentionally does not label
%   the variables; search is added by the public solver in Milestone 3.

constrain_puzzle(Puzzle, Board) :-
    valid_puzzle(Puzzle),
    zeros_to_variables(Puzzle, Board),
    sudoku_constraints(Board).


zeros_to_variables(Puzzle, Board) :-
    maplist(normalize_row, Puzzle, Board).


normalize_row(Row, NormalizedRow) :-
    maplist(normalize_cell, Row, NormalizedRow).


normalize_cell(Cell, NormalizedCell) :-
    (   Cell =:= 0
    ->  true
    ;   NormalizedCell = Cell
    ).


sudoku_constraints(Rows) :-
    append(Rows, Cells),
    Cells ins 1..9,

    maplist(all_distinct, Rows),

    transpose(Rows, Columns),
    maplist(all_distinct, Columns),

    puzzle_boxes(Rows, Boxes),
    maplist(all_distinct, Boxes).


puzzle_boxes([], []).

puzzle_boxes([First, Second, Third|Rows], Boxes) :-
    row_boxes(First, Second, Third, CurrentBoxes),
    puzzle_boxes(Rows, RemainingBoxes),
    append(CurrentBoxes, RemainingBoxes, Boxes).


row_boxes([], [], [], []).

row_boxes(
    [A, B, C|First],
    [D, E, F|Second],
    [G, H, I|Third],
    [[A, B, C, D, E, F, G, H, I]|Boxes]
) :-
    row_boxes(First, Second, Third, Boxes).
