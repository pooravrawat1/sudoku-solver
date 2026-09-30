# Sudoku Solver Design

## 1. Design Overview

The project uses two independent solver implementations over a shared puzzle format:

- a declarative SWI-Prolog solver that posts Sudoku rules as CLP(FD) constraints and asks the runtime to label the remaining variables; and
- an imperative Python solver that controls candidate selection, assignment, recursion, and rollback directly.

Keeping fixtures, result validation, and measurements consistent makes the final comparison easier to reproduce while preserving the intended contrast between programming paradigms.

## 2. Proposed Repository Structure

```text
sudoku-solver/
|-- README.md
|-- data/
|   `-- puzzles/
|       |-- easy.txt
|       |-- hard.txt
|       |-- solved.txt
|       `-- unsolvable.txt
|-- docs/
|   |-- requirements.md
|   |-- design.md
|   `-- tasks.md
|-- src/
|   |-- prolog/
|   |   `-- sudoku.pl
|   `-- python/
|       `-- sudoku.py
|-- tests/
|   |-- prolog/
|   |   `-- test_sudoku.pl
|   `-- python/
|       `-- test_sudoku.py
|-- scripts/
|   `-- benchmark.py
`-- reports/
    `-- comparison.md
```

Files may be combined while the prototype is small, but the public solver logic should remain separate from tests and benchmarking.

## 3. Data Design

### 3.1 Canonical Puzzle Format

Fixture files contain nine lines of nine digits. Digits `1` through `9` are clues, and `0` is an empty cell. Optional whitespace may be allowed by the loaders, but the stored fixtures should use one consistent style.

Example:

```text
530070000
600195000
098000060
800060003
400803001
700020006
060000280
000419005
000080079
```

In memory, both implementations use a list of nine row lists, with nine integers per row. The Prolog adapter replaces each `0` with a fresh logic variable before posting constraints.

### 3.2 Result Contract

A successful result is a new 9 x 9 board containing only values `1` through `9`. It must preserve all clues and satisfy every Sudoku unit.

The core APIs use language-appropriate failure behavior:

- Prolog: `solve(+Puzzle, -Solution)` succeeds with a solution or fails when a valid puzzle has no solution.
- Python: `solve(board)` returns a solved copy or `None` when a valid puzzle has no solution.

Invalid input should be detected before search. A command-line wrapper may translate exceptions or predicate failure into the user-facing statuses `solved`, `unsolvable`, and `invalid`.

## 4. Component Design

```mermaid
flowchart LR
    F[Shared puzzle fixtures] --> PL[Prolog loader and validator]
    F --> PY[Python loader and validator]
    PL --> CS[CLP(FD) constraints]
    CS --> LB[Labeling search]
    PY --> BT[Explicit backtracking]
    LB --> V[Solution validation]
    BT --> V
    V --> B[Benchmark records]
    B --> R[Comparative report or presentation]
```

### 4.1 Shared Responsibilities

The implementations should behave equivalently at their boundaries:

1. Load or receive the input board.
2. Validate shape, value range, and conflicts among clues.
3. Solve without changing the meaning of the input clues.
4. Validate the completed result.
5. Present the result in a stable, human-readable format.

The code does not need to be artificially identical. Its structural differences are evidence for the comparative study.

### 4.2 Prolog Module

Suggested module interface:

```prolog
:- module(sudoku, [solve/2, valid_puzzle/1, valid_solution/2]).
:- use_module(library(clpfd)).
```

Suggested solution flow:

1. `valid_puzzle/1` verifies that the input has nine rows, each row has nine integers, all values are in `0..9`, and nonzero clues do not conflict.
2. `zeros_to_variables/2` constructs a board in which zero cells become fresh logic variables and clues remain fixed integers.
3. `append/2` collects all cells and `ins 1..9` assigns their finite domain.
4. `maplist(all_distinct, Rows)` posts row constraints.
5. `transpose/2` derives columns and applies `all_distinct` to each column.
6. A box predicate groups each set of three adjacent rows into 3 x 3 boxes and applies `all_distinct` to each box.
7. `labeling/2` searches for concrete values only after all constraints have been posted.
8. `valid_solution/2` provides a separate final correctness check and verifies that clues were preserved.

The initial implementation should use a documented labeling option, such as `labeling([ffc], Cells)`. Any option change used for performance experiments must be recorded because it changes search behavior.

The core solving predicate should remain declarative: it describes valid board relationships rather than manually iterating over candidate digits.

### 4.3 Python Module

Suggested public functions:

```python
def load_puzzle(path: str) -> list[list[int]]: ...
def validate_puzzle(board: list[list[int]]) -> None: ...
def solve(board: list[list[int]]) -> list[list[int]] | None: ...
def is_solution(original: list[list[int]], candidate: list[list[int]]) -> bool: ...
```

Suggested backtracking flow:

1. Validate the input and make a copy so the caller's board is not unexpectedly mutated.
2. Select an empty cell. A simple row-major rule is the clearest baseline; if a minimum-remaining-values heuristic is added, document it.
3. Try candidate values `1` through `9` in a stable order.
4. Reject a candidate if it is already present in the cell's row, column, or box.
5. Assign a valid candidate and recursively solve the remaining board.
6. Return the board when no empty cell remains.
7. Reset the cell to `0` when a recursive branch fails, then try the next candidate.
8. Return `None` when every candidate has failed.

This implementation intentionally exposes control flow that CLP(FD) handles inside the Prolog system.

### 4.4 Independent Solution Validation

Each implementation should validate completed boards without reusing its search logic. For every row, column, and box, the validator checks equality with the set `{1, 2, ..., 9}`. It also checks that each original clue equals the value at the same location in the solution.

Separate validation prevents a solver bug from being hidden by an identical bug in the test assertion.

## 5. Error Handling

| Condition | Core behavior | Demonstration behavior |
| --- | --- | --- |
| Wrong dimensions | Validation error/failure | Print `invalid` with a concise reason |
| Non-integer or value outside `0..9` | Validation error/failure | Print `invalid` with a concise reason |
| Conflicting fixed clues | Validation error/failure | Print `invalid` with a concise reason |
| Valid board with no solution | Normal no-solution result | Print `unsolvable` |
| Valid solvable board | Return complete board | Print `solved` and the board |

Invalid input and an unsolvable valid puzzle must remain distinguishable in tests, even if the smallest Prolog API uses failure for both and a wrapper performs the distinction.

## 6. Testing Design

### 6.1 Prolog Tests

Use SWI-Prolog `plunit` tests to cover the public predicates. Include success tests, expected-failure tests, invalid-input tests, clue preservation, and final-board validation.

Suggested command:

```sh
swipl -q -g run_tests -t halt tests/prolog/test_sudoku.pl
```

### 6.2 Python Tests

Use the Python standard library's `unittest` module so the baseline remains dependency-free.

Suggested command:

```sh
python3 -m unittest discover -s tests/python -v
```

### 6.3 Cross-Implementation Checks

Both suites must reference equivalent fixture data and assert the same behavioral outcomes. Exact completed boards need not match when a puzzle has multiple solutions, but every returned board must validate and preserve the clues.

## 7. Benchmark and Comparison Design

### 7.1 Runtime Procedure

The benchmark script should:

1. Record the operating system, processor description, SWI-Prolog version, and Python version.
2. Use the same named puzzles for both solvers.
3. Perform at least one unrecorded warm-up run per implementation.
4. Perform a documented number of recorded runs per puzzle.
5. Validate every result before accepting a timing.
6. Record individual elapsed times and report the median to reduce sensitivity to isolated system noise.
7. Write results in a simple table or CSV that can be copied into the report.

Process startup, garbage collection, CLP(FD) propagation, and heuristic differences can affect measurements. The report should describe the benchmark as an educational comparison, not a controlled proof that one language is faster.

### 7.2 Source-Line Procedure

Count the solver modules only, excluding tests, fixtures, blank lines, and comment-only lines. Document the command or script used and report both the count and the exact included files.

### 7.3 Qualitative Comparison

The final analysis should address:

- how directly each implementation expresses Sudoku rules;
- where variable binding occurs;
- who controls candidate selection and backtracking;
- the amount and visibility of control-flow code;
- how easy it is to change a constraint;
- how validation and error handling affect code size; and
- why line count and runtime should be interpreted with care.

## 8. Key Design Decisions

| Decision | Rationale |
| --- | --- |
| Standard 9 x 9 boards only | Matches the proposal and keeps the focus on language paradigms. |
| Shared zero-based fixture format | Makes test and benchmark inputs repeatable across languages. |
| Fresh Prolog variables replace zeros | Lets CLP(FD) bind unknowns naturally through unification. |
| All constraints posted before labeling | Separates the declarative model from search and enables propagation. |
| Python owns explicit rollback | Makes the imperative control flow visible for comparison. |
| Independent final validation | Guards against false success and improves benchmark reliability. |
| Median runtime reported | Reduces distortion from isolated timing noise. |

## 9. Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| A hard puzzle makes the Python baseline too slow | Choose representative fixtures; document and, if necessary, consistently apply a cell-selection heuristic. |
| Different puzzle parsers change the effective inputs | Store canonical fixtures and test parsed boards in both languages. |
| Invalid clues are confused with an unsolvable puzzle | Validate shape, range, and clue conflicts before search. |
| Runtime results are overstated | Record the environment and procedure, use repeated runs, and state limitations. |
| CLP(FD) details obscure the course explanation | Keep the Prolog module small and explain domains, constraints, propagation, and labeling separately. |
| Solvers mutate shared test inputs | Copy Python inputs and construct a separate Prolog constraint board. |

## 10. Completion Criteria

The design is complete when both solvers implement the shared behavioral contract, all required tests pass, benchmark data can be reproduced, and the report connects observed code differences to the four course concepts named in the proposal.
