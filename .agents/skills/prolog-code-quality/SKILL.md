---
name: prolog-code-quality
description: Write, format, lint, and review readable SWI-Prolog source and plunit tests for this Sudoku project. Use when creating or changing .pl files, or when the user requests a Prolog style, quality, or code-review pass.
---

# Prolog Code Quality

Keep the Prolog implementation spacious, declarative, and easy for an instructor to review. Correctness and clarity take priority over minimizing line count.

## Before editing

- Read `docs/requirements.md` and `docs/design.md` when a change affects solver behavior or public predicates.
- Inspect nearby Prolog code and preserve any established convention that does not conflict with this skill.
- Keep solver logic, input handling, tests, and benchmark integration separate as described in the design.

## Source organization

- Put the module declaration first, followed by library imports, public predicates, and private helpers.
- List exported predicates one per line when the list would otherwise be visually dense.
- Keep all clauses of one predicate together. Put the base case before recursive clauses when that makes the recursion easier to follow.
- Separate predicate groups with whitespace and a short section comment when the grouping is not already obvious.
- Prefer several focused predicates over one large predicate that mixes validation, constraint modeling, search, and presentation.
- Do not compress code merely to reduce the source-line count used in the project comparison.

Use a readable module header such as:

```prolog
:- module(sudoku,
    [ solve/2,
      valid_puzzle/1,
      valid_solution/2
    ]).

:- use_module(library(clpfd)).
```

## Layout and naming

- Use four spaces for continuation indentation and never use tabs.
- Write one meaningful goal per line in a multi-goal clause. A short fact or wrapper may remain on one line.
- Put one space after commas and around infix operators. Keep list patterns compact, such as `[Row|Rows]`.
- Leave a blank line between distinct predicates; use additional space where it makes stages of the logic easier to scan.
- Use descriptive `snake_case` predicate and atom names.
- Use descriptive `CamelCase` variable names such as `Puzzle`, `Solution`, `Rows`, and `RemainingRows`.
- Use `_` only for a genuinely ignored value. Use a named singleton such as `_Status` when its role matters to the reader.
- Keep lines reasonably scannable, normally at or below 100 characters. Break a long term at logical argument or goal boundaries rather than mechanically wrapping it.

## Predicate documentation

- Add PlDoc comments to exported predicates and non-obvious internal predicates.
- State argument roles, accepted representation, success/failure behavior, and determinism.
- Document why a surprising choice exists; do not narrate self-explanatory syntax.

Example:

```prolog
%!  solve(+Puzzle, -Solution) is semidet.
%
%   Unifies Solution with a completed 9 x 9 Sudoku board that preserves
%   Puzzle's fixed clues. Fails when Puzzle is valid but has no solution.
```

## Logic and CLP(FD) conventions

- Keep the core solver relational and declarative. Do not reproduce Python-style candidate loops, mutation, or manual rollback in Prolog.
- Convert every input `0` to a different fresh logic variable while preserving each nonzero clue.
- Post domains and every row, column, and box constraint before calling `labeling/2`.
- Keep the selected labeling options in one clearly named location and document why they were chosen.
- Use CLP(FD) relations such as `#=`, `#\=`, `#<`, and `#>` for finite-domain arithmetic. Use `is/2` only when one-way evaluation is intentionally required.
- Use unification intentionally. Do not use `=/2` where arithmetic or finite-domain equality is meant.
- Avoid cuts. When a cut is necessary for committed input dispatch or determinism, make its scope small and document why alternatives must not be considered.
- Do not apply negation as failure to insufficiently instantiated goals. Establish the necessary groundness first or use an appropriate logical constraint such as `dif/2`.
- Make invalid input and a valid-but-unsatisfiable puzzle distinguishable at the public boundary or wrapper layer.
- Preserve the project contract: `solve(+Puzzle, -Solution)` succeeds with solutions and fails when a valid puzzle has none. Do not silently change it into an exception-based or status-returning API.

## Review checklist

When reviewing or completing Prolog code, check all of the following:

1. The module exports match the documented public API.
2. Board shape, integer type, range, and initial clue conflicts are validated before search.
3. Repeated zeros are not incorrectly treated as duplicate clues.
4. Each zero becomes a fresh variable; no two empty cells accidentally share one variable.
5. Every cell has domain `1..9`, and all 27 units receive an `all_distinct/1` constraint.
6. All constraints are posted before labeling, and labeling variables are in a stable board order.
7. Returned solutions preserve clues and pass an independent validator.
8. Invalid, unsolvable, solved, easy, and hard cases are covered with `plunit` tests.
9. Recursion has a clear base case and makes structural progress.
10. There are no unintended singleton warnings, undefined predicates, silent choicepoints, or unexplained cuts.

For a review-only request, report findings in severity order with file and line references. Do not edit files unless the user requested changes.

## Automated check

After changing Prolog source or tests, run:

```sh
.agents/skills/prolog-code-quality/scripts/check_prolog.sh
```

The script treats compiler warnings as failures and runs the Prolog test suite when tests exist. If SWI-Prolog is not installed, report that limitation clearly instead of claiming the code passed.
