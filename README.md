# Sudoku Solver

Comparing a declarative SWI-Prolog Sudoku solver with an explicit Python backtracking solver.

## Requirements

Verified with:

- SWI-Prolog 10.0.2
- Python 3.14.7

On macOS, install SWI-Prolog with:

```sh
brew install swi-prolog
```

Verify the environment:

```sh
swipl --version
python3 --version
swipl -q -g "use_module(library(clpfd)),halt"
```

## Puzzle format

Puzzle files contain nine lines of nine digits. `1` through `9` are clues and
`0` represents an empty cell.

Both solvers receive nine rows of nine integers. Prolog replaces zeros with
fresh logic variables; Python keeps zeros until its backtracking search fills
them.

## Commands

Run these commands from the repository root.

```sh
# Prolog tests
swipl -q -g run_tests -t halt tests/prolog/test_sudoku.pl

# Prolog quality checks
.agents/skills/prolog-code-quality/scripts/check_prolog.sh

# Prolog fixture demonstrations
swipl -q -s scripts/demo_prolog.pl -- easy
swipl -q -s scripts/demo_prolog.pl -- hard
swipl -q -s scripts/demo_prolog.pl -- unsolvable
swipl -q -s scripts/demo_prolog.pl -- invalid/duplicate_box
```

The demonstration prints `solved` followed by nine rows, `unsolvable`, or
`invalid`. It accepts the named files under `data/puzzles/`, including the
seven `invalid/...` fixtures. From the SWI-Prolog console, import the module
with `use_module('src/prolog/sudoku').` and call
`solve(Puzzle, Solution).` The public `valid_puzzle/1` predicate checks input;
`valid_solution/2` checks a completed board and clue preservation. `solve/2`
fails for both invalid and valid but unsolvable puzzles, so check
`valid_puzzle/1` first when the distinction matters. Search uses
`labeling([ffc], Cells)` after posting all Sudoku constraints. The `ffc`
option chooses a cell with a small remaining domain and high constraint
degree first.

Python tests, its demonstration, and the benchmark will be added in Milestone 4.
The Milestone 3 acceptance run is recorded in
[reports/milestone-3.md](reports/milestone-3.md).

See [requirements](docs/requirements.md), [design](docs/design.md), and
[implementation tasks](docs/tasks.md) for project details.
