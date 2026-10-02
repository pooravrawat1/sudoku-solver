# Prolog Concepts Used in the Solver

## Predicates and rules

A predicate describes a relationship. For example, `solve(Puzzle, Solution)`
will state when `Solution` is a valid completion of `Puzzle`. A rule succeeds
only when every goal in its body succeeds.

## Queries and goals

A query asks Prolog to satisfy one or more goals. Calling
`solve(Puzzle, Solution)` asks Prolog to find a binding for `Solution` that
satisfies the solver's validation, Sudoku constraints, and search goals.

## Unification and binding

Unification makes compatible terms equal. Empty cells become logic variables,
and those variables become bound as constraints narrow their possible values.
A variable is local to its clause unless it is passed to another predicate.

## Recursion

Recursive predicates will process repeated structures such as rows and 3 x 3
boxes. Each recursive clause has a base case and consumes part of its input so
that it moves toward that base case.

## Constraints and propagation

`library(clpfd)` gives every unknown cell the domain `1..9`. Row, column, and
box predicates apply `all_distinct/1`. Constraint propagation removes values
that can no longer satisfy those relationships before explicit search begins.

The code maps Sudoku concepts to CLP(FD) as follows:

| Sudoku concept | Prolog representation |
| --- | --- |
| Empty cell | A fresh logic variable created from an input `0` |
| Fixed clue | The original integer, preserved through unification |
| Allowed values | `Cells ins 1..9` |
| Row uniqueness | `all_distinct/1` on each input row |
| Column uniqueness | `transpose/2`, then `all_distinct/1` on each column |
| Box uniqueness | Three-row groups converted into boxes for `all_distinct/1` |
| Deduction | CLP(FD) propagation narrows variable domains |

All domains and uniqueness constraints are posted before search. This lets
propagation share information across rows, columns, and boxes before Prolog
selects any concrete candidate values.

## Search and backtracking

After all constraints are posted, `labeling/2` selects concrete values for the
remaining variables. If a choice causes a contradiction, Prolog backtracks and
tries another permitted value. This replaces the explicit assignment and
rollback code used by the Python solver.
