:- use_module('../src/prolog/sudoku_trace').
:- use_module(library(http/json)).

:- initialization(main, main).


main :-
    json_read_dict(current_input, Request),
    trace_puzzle(Request.board).
