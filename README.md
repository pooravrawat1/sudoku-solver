# Sudoku Solver

A small course project comparing a declarative SWI-Prolog Sudoku solver with an
explicit Python backtracking solver.

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

These commands will become active as their milestone is implemented:

```sh
# Prolog tests
swipl -q -g run_tests -t halt tests/prolog/test_sudoku.pl

# Python tests
python3 -m unittest discover -s tests/python -v

# Prolog quality checks
.agents/skills/prolog-code-quality/scripts/check_prolog.sh

# Benchmark
python3 scripts/benchmark.py
```

The final solver demonstration commands will be added with tasks T-17 and T-25.

See [requirements](docs/requirements.md), [design](docs/design.md), and
[implementation tasks](docs/tasks.md) for project details.
