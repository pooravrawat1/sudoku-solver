# Puzzle Fixtures

The four canonical fixtures use nine lines of nine digits, with `0` for an
empty cell.

- `easy.txt` is the example puzzle used in the project design.
- `solved.txt` is the completed form of `easy.txt`.
- `hard.txt` is a sparse 17-clue puzzle selected to exercise deeper search; the
  project does not claim a formal difficulty rating.
- `unsolvable.txt` is derived from `easy.txt` by adding a locally legal `1` in
  row 1, column 3. The original puzzle has a unique solution containing `4` in
  that cell, so the added clue makes completion impossible without creating an
  immediate row, column, or box duplicate.

The `invalid` directory contains deliberately malformed inputs for validation
tests. The out-of-range case uses whitespace so that `10` remains one cell, and
the non-integer case uses `x` as an invalid token.

`search.txt` is an additional visual-demo fixture, made by retaining 23 cells
from `solved.txt` (Python `random.Random(3).sample(range(81), 23)`). It exercises
labeling and rollback in SWI-Prolog 10.0.2. It may have multiple solutions and
is not part of the benchmark or a claim about puzzle difficulty.
