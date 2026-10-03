:- module(puzzle_io,
    [ load_puzzle/2,
      print_board/1
    ]).

:- use_module(library(readutil)).


%!  load_puzzle(+File, -Puzzle) is det.
%
%   Reads rows of compact digits or whitespace-separated cells from File.
%   Non-numeric tokens remain atoms so valid_puzzle/1 can reject them.

load_puzzle(File, Puzzle) :-
    read_file_to_string(File, Contents, []),
    split_string(Contents, "\n", "\r\n", Lines),
    maplist(parse_row, Lines, Puzzle).


parse_row(Line, Row) :-
    split_string(Line, " \t", " \t", Tokens),
    (   Tokens = [Compact],
        string_length(Compact, 9)
    ->  string_chars(Compact, Cells)
    ;   Cells = Tokens
    ),
    maplist(parse_cell, Cells, Row).


parse_cell(Token, Cell) :-
    (   string(Token)
    ->  Text = Token
    ;   atom_string(Token, Text)
    ),
    (   catch(number_string(Number, Text), _, fail)
    ->  Cell = Number
    ;   atom_string(Cell, Text)
    ).


%!  print_board(+Board) is det.
%
%   Writes a completed board in the same compact row format as the fixtures.

print_board(Board) :-
    maplist(print_row, Board).


print_row(Row) :-
    atomic_list_concat(Row, '', Text),
    writeln(Text).
