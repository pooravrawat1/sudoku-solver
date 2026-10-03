:- module(sudoku,
    [ solve/2,
      valid_puzzle/1,
      valid_solution/2
    ]).

:- use_module(library(clpfd)).


%!  solve(+Puzzle, -Solution) is nondet.
%
%   Solves a 9 x 9 integer Puzzle, using 0 for an empty cell. Each result is
%   a completed board that preserves the clues. Fails for invalid input or
%   a valid puzzle without a solution; use valid_puzzle/1 to distinguish them.

solve(Puzzle, Solution) :-
    constrain_puzzle(Puzzle, Solution),
    append(Solution, Cells),
    labeling_options(Options),
    labeling(Options, Cells),
    valid_solution(Puzzle, Solution).


% First-fail combined with constraint degree chooses the most restricted cell.
labeling_options([ffc]).


%!  valid_puzzle(+Puzzle) is semidet.
%
%   True when Puzzle is a 9 x 9 list of integers in the range 0 through 9
%   and its nonzero clues do not conflict in any row, column, or 3 x 3 box.

valid_puzzle(Puzzle) :-
    is_list(Puzzle),
    length(Puzzle, 9),
    maplist(valid_row, Puzzle),
    clues_are_consistent(Puzzle).


%!  valid_solution(+Puzzle, +Solution) is semidet.
%
%   True when Solution is a complete 9 x 9 board with every digit in each
%   row, column, and box, and every nonzero clue from Puzzle is unchanged.
%   Checks concrete integers and units without using CLP(FD) search.

valid_solution(Puzzle, Solution) :-
    valid_puzzle(Puzzle),
    is_list(Solution),
    length(Solution, 9),
    maplist(completed_row, Solution),
    puzzle_units(Solution, Units),
    maplist(complete_unit, Units),
    maplist(clues_preserved, Puzzle, Solution).


completed_row(Row) :-
    is_list(Row),
    length(Row, 9),
    maplist(completed_cell, Row).


completed_cell(Cell) :-
    integer(Cell),
    between(1, 9, Cell).


complete_unit(Unit) :-
    sort(Unit, [1, 2, 3, 4, 5, 6, 7, 8, 9]).


clues_preserved(PuzzleRow, SolutionRow) :-
    maplist(clue_preserved, PuzzleRow, SolutionRow).


clue_preserved(0, _).
clue_preserved(Clue, Value) :-
    Clue =\= 0,
    Clue =:= Value.


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
%   posts every Sudoku constraint on Board without labeling the variables.

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
