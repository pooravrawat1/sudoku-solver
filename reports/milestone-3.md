# Milestone 3 Acceptance Record

Run from the repository root on October 3, 2026 with SWI-Prolog 10.0.2
for arm64-darwin.

| Check | Command | Result |
| --- | --- | --- |
| Full Prolog suite | `swipl -q -g run_tests -t halt tests/prolog/test_sudoku.pl` | 26 of 26 tests passed |
| Compile and test quality gate | `.agents/skills/prolog-code-quality/scripts/check_prolog.sh` | All Prolog files compiled without warnings; 26 tests passed |
| Easy demonstration | `swipl -q -s scripts/demo_prolog.pl -- easy` | `solved`, followed by nine complete rows |
| Hard demonstration | `swipl -q -s scripts/demo_prolog.pl -- hard` | `solved`, followed by nine complete rows |
| Unsolvable demonstration | `swipl -q -s scripts/demo_prolog.pl -- unsolvable` | `unsolvable` |
| Invalid demonstration | `swipl -q -s scripts/demo_prolog.pl -- invalid/duplicate_box` | `invalid` |

The suite checks each returned solution with `valid_solution/2`, which verifies
completed rows, columns, boxes, and clue preservation without using search.
