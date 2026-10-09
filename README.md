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

### Interactive Sudoku lab

```sh
python3 scripts/serve_ui.py
```

Open **http://127.0.0.1:8000** for a playable Sudoku board beside Prolog's
execution journal. No additional packages or frontend build are needed.
Use `--port 8001` if port 8000 is already occupied. Stop the server with Ctrl+C.

- Select a square and type 1–9, or use the number pad; Backspace erases.
- Choose a fixture or select **Custom board** to enter clues. **Check board**
  flags direct conflicts; it does not prove a partial board is solvable.
- Press **Watch Prolog**, then pause, step, change speed, or scrub the timeline.
- Select **Backtracking demo** to see search bindings being undone. The easy
  and hard benchmark fixtures can be solved entirely by propagation.
- Reset returns to your clues and lets you play again. Player-entered digits
  become additional clues for the next Prolog run.

The interface replays JSON events recorded from an actual SWI-Prolog run.
`src/prolog/sudoku_trace.pl` reuses the core normalization, box layout, and
labeling options, posts the same constraints in the same order, and records
finite domains after each `all_distinct/1`. During native `labeling([ffc], ...)`,
[`freeze/2`](https://www.swi-prolog.org/pldoc/man?predicate=freeze%2F2) observers
record variable bindings; a failing alternative records their undo. The journal
does not distinguish a labeling choice from a binding forced by propagation,
and it does not expose every internal CLP(FD) operation. Search-phase candidate
domains are hidden because only binding changes are recorded during labeling.
The displayed query describes the solver; the UI executes `trace_puzzle/1`.

The original solver and benchmark path are unchanged. Trace timings are not
benchmark timings. A run is limited to 15 seconds and 20,000 events; the local
server listens only on `127.0.0.1`. Replay begins after recording finishes.

The interface follows the **Industrial** preset from
[Ilm-Alan/frontend-design](https://github.com/Ilm-Alan/frontend-design): black
surfaces, IBM Plex Mono, amber signals, and flat square panels. The font files
are bundled locally under their [SIL Open Font License](src/web/fonts/OFL.txt).
During playback, use a log entry's **Inspect** button to select its cell and
highlight the matching row and column coordinates.

### Solver and benchmark commands

```sh
# Prolog tests
swipl -q -g run_tests -t halt tests/prolog/test_sudoku.pl

# Prolog quality checks
.agents/skills/prolog-code-quality/scripts/check_prolog.sh

# Python tests
python3 -m unittest discover -s tests/python -v

# Prolog fixture demonstrations
swipl -q -s scripts/demo_prolog.pl -- easy
swipl -q -s scripts/demo_prolog.pl -- hard
swipl -q -s scripts/demo_prolog.pl -- unsolvable
swipl -q -s scripts/demo_prolog.pl -- invalid/duplicate_box

# Python fixture demonstrations
python3 scripts/demo_python.py easy
python3 scripts/demo_python.py hard
python3 scripts/demo_python.py unsolvable
python3 scripts/demo_python.py invalid/duplicate_box

# Repeat the recorded comparison (one warm-up and seven measured runs per case)
python3 scripts/benchmark.py

# Count nonblank, non-comment-only lines in the two solver modules
python3 scripts/count_lines.py
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

Python exposes `validate_puzzle(board)`, `solve(board)`, and
`is_solution(original, candidate)` in `src/python/sudoku.py`. Invalid input
raises `ValueError`; valid puzzles with no solution return `None`. The solver
copies its input, uses minimum remaining values to select an empty cell, and
tries digits in ascending order. Both demos print the same three statuses.

The benchmark uses the shared easy and hard fixtures. It excludes fixture
loading and process startup from timing, checks every result independently,
and writes raw timings, medians, environment details, and source-line counts
to `reports/benchmark/`. See [the Milestone 4 record](reports/milestone-4.md)
for the method and current results. The [Milestone 3 record](reports/milestone-3.md)
contains the earlier Prolog acceptance run.

See [requirements](docs/requirements.md), [design](docs/design.md), and
[implementation tasks](docs/tasks.md) for project details.
