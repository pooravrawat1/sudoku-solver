# Milestone 4 Acceptance Record

Run on October 6, 2026, on Darwin 25.6.0 arm64 with 15 logical CPUs,
SWI-Prolog 10.0.2, and Python 3.14.7. The operating system reported the
processor as `arm`; the exact chip model was unavailable.

## Acceptance checks

| Check | Command | Result |
| --- | --- | --- |
| Prolog suite and compilation | `.agents/skills/prolog-code-quality/scripts/check_prolog.sh` | 26 tests passed; no compiler warnings |
| Python suite | `python3 -m unittest discover -s tests/python -v` | 14 tests passed |
| Easy Python demo | `python3 scripts/demo_python.py easy` | `solved`, matching `solved.txt` |
| Hard Python demo | `python3 scripts/demo_python.py hard` | `solved`, same validated board as Prolog |
| Unsolvable Python demo | `python3 scripts/demo_python.py unsolvable` | `unsolvable` |
| Invalid Python demo | `python3 scripts/demo_python.py invalid/duplicate_box` | `invalid` |
| Benchmark | `python3 scripts/benchmark.py` | Results saved in `reports/benchmark/` |
| Source count | `python3 scripts/count_lines.py` | Prolog 93; Python 97 |

## Measurement method and results

The benchmark loaded the same `easy.txt` and `hard.txt` boards for both
solvers. It ran one warm-up and seven measured runs per solver and puzzle.
Warm-ups were validated but excluded from the raw CSV and medians. Each
measured solution was checked by Python's `is_solution(original, candidate)`
after timing. A failed check aborts the benchmark.

Python used `time.perf_counter_ns()` around `solve(board)` in one interpreter.
Prolog used `get_time/1` around `once(solve(Puzzle, Solution))` in one persistent
SWI-Prolog process. These intervals include each solver's input validation,
search, and final validation. Fixture loading, process startup, interprocess
communication, and the benchmark's external validation were excluded. The
summary reports the median of the seven measured wall-clock durations.

| Puzzle | Prolog median (ms) | Python median (ms) |
| --- | ---: | ---: |
| Easy | 7.648945 | 1.510333 |
| Hard | 14.863014 | 39.344667 |

The exact timing samples, validated 81-digit solutions, minimums and maximums,
and environment details are in [raw.csv](benchmark/raw.csv),
[summary.csv](benchmark/summary.csv), and
[environment.json](benchmark/environment.json). These results describe one
machine and one run session. The solvers use different search heuristics
(`ffc` in Prolog and minimum remaining values in Python), and the timing APIs
differ, so these figures do not isolate language runtime performance.

## Source-line procedure

`python3 scripts/count_lines.py` counts only `src/prolog/sudoku.pl` and
`src/python/sudoku.py`. It excludes blank lines and lines whose first
non-whitespace character is `%` or `#`, respectively. Input/output modules,
tests, demos, and benchmark code are outside the count. Python docstring lines
count as source under this rule. The saved counts are in
[source_lines.csv](benchmark/source_lines.csv).
