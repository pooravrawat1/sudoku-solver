# Sudoku Solver Implementation Tasks

## 1. Task Conventions

- Tasks are ordered by dependency and grouped by the proposal's milestones.
- An unchecked box means the repository does not yet provide evidence that the task is complete.
- Requirement identifiers refer to `docs/requirements.md`.
- The dates below are proposal targets, not claims about current completion status.

## 2. Milestone 1 - Environment and Foundation

**Proposal target:** Mid-September 2026

- [x] **T-01 - Install and verify tools.** Install SWI-Prolog and Python 3, then record their versions. Confirm that `library(clpfd)` loads successfully. (NFR-03)
- [x] **T-02 - Create the project structure.** Add the `src`, `data`, `tests`, `scripts`, and `reports` directories described in the design. (NFR-04)
- [x] **T-03 - Document developer commands.** Add setup, test, solver, and benchmark command placeholders to `README.md`; fill them in as components are implemented. (NFR-02)
- [x] **T-04 - Confirm the shared board contract.** Use nine rows of nine integers with `0` as an empty cell and document the in-memory forms for Prolog and Python. (FR-01, FR-02)
- [x] **T-05 - Review core Prolog concepts.** Prepare concise project notes on predicates, recursion, unification, logic variables, goals, and backtracking for use in the final explanation. (FR-22)

**Exit criteria:** Both runtimes work, CLP(FD) loads, the repository structure exists, and the common board representation is fixed.

## 3. Milestone 2 - Constraints and Test Data

**Proposal target:** Early October 2026

- [x] **T-06 - Add canonical fixtures.** Add easy, hard, solved, and valid-but-unsolvable puzzle files with their source or selection rationale. (FR-08)
- [x] **T-07 - Add invalid test boards.** Create cases for bad dimensions, out-of-range values, and duplicate clues in a row, column, and box. (FR-03)
- [x] **T-08 - Implement Prolog board validation.** Check dimensions, integer values, range, and conflicts among nonzero clues. (FR-01 through FR-03)
- [x] **T-09 - Normalize Prolog cells.** Convert `0` cells to fresh logic variables while preserving fixed clues. (FR-04, FR-10)
- [x] **T-10 - Implement row constraints.** Constrain all cells to `1..9` and apply `all_distinct/1` to every row. (FR-10, FR-11)
- [x] **T-11 - Implement column constraints.** Use `transpose/2` and apply `all_distinct/1` to every column. (FR-11)
- [x] **T-12 - Implement box constraints.** Group the board into nine 3 x 3 boxes and apply `all_distinct/1` to each. (FR-11)
- [x] **T-13 - Document CLP(FD) mapping.** Explain how domains, `all_distinct/1`, propagation, and unification correspond to Sudoku rules. (FR-22)

**Exit criteria:** All Sudoku constraints can be posted for a valid 9 x 9 board, and invalid boards are rejected before labeling.

## 4. Milestone 3 - Complete and Test the Prolog Solver

**Proposal target:** Late October 2026

- [ ] **T-14 - Implement the public Prolog solver.** Add `solve/2`, post all constraints, and label the remaining variables with a documented option. (FR-09 through FR-13)
- [ ] **T-15 - Implement Prolog solution validation.** Check all units and clue preservation independently from search. (FR-04, FR-05, NFR-01)
- [ ] **T-16 - Add Prolog unit tests.** Cover easy, hard, solved, unsolvable, malformed, conflicting, and clue-preservation cases with `plunit`. (FR-03 through FR-08, NFR-08)
- [ ] **T-17 - Add a Prolog demonstration command.** Make it easy to run a named fixture and print a solved board or clear status. (FR-17)
- [ ] **T-18 - Verify Prolog acceptance criteria.** Run the full Prolog suite and save the command and result for the project record. (NFR-01, NFR-02)

**Exit criteria:** The Prolog solver passes its automated tests and solves the selected easy and hard boards from a documented command.

## 5. Milestone 4 - Python Baseline and Measurements

**Proposal target:** Early November 2026

- [ ] **T-19 - Implement Python input validation.** Enforce the shared shape, type, range, and initial-conflict rules. (FR-01 through FR-03)
- [ ] **T-20 - Implement candidate checking.** Add clear row, column, and box checks for a proposed value. (FR-05, FR-14)
- [ ] **T-21 - Implement recursive backtracking.** Select an empty cell, try candidates, recurse, and roll back failed assignments. (FR-14 through FR-16)
- [ ] **T-22 - Protect caller input.** Solve a board copy and return a solved board or `None` without leaving partial mutations in the input. (NFR-04)
- [ ] **T-23 - Implement Python solution validation.** Check units and original clues independently from the backtracking search. (FR-04, FR-05, NFR-01)
- [ ] **T-24 - Add Python unit tests.** Match the Prolog suite's behavioral cases with `unittest`. (FR-03 through FR-08, NFR-08)
- [ ] **T-25 - Add a Python demonstration command.** Run the same easy and hard fixtures and print the result consistently. (FR-17)
- [ ] **T-26 - Implement the benchmark harness.** Record environment details, warm-ups, repeated timings, validation outcomes, and medians for both solvers. (FR-18, NFR-06)
- [ ] **T-27 - Implement the line-count procedure.** Count nonblank, non-comment source lines in the declared solver files and record the command. (FR-19)
- [ ] **T-28 - Collect comparison data.** Run both implementations on the same machine and same fixtures, then save raw and summarized results. (FR-18, FR-19)

**Exit criteria:** Both implementations pass equivalent tests, solve the same demonstration puzzles, and have reproducible runtime and source-line records.

## 6. Milestone 5 - Analysis and Submission

**Proposal target:** Late November 2026

- [ ] **T-29 - Draft the structural comparison.** Compare how Prolog constraints and Python control flow represent rows, columns, boxes, variable binding, and search. (FR-20, FR-21)
- [ ] **T-30 - Analyze the measurements.** Present runtime and line-count tables, explain observed results, and state benchmark limitations. (FR-18 through FR-21)
- [ ] **T-31 - Connect results to course concepts.** Address logic programming, declarative versus imperative paradigms, unification and binding, interpretation, depth-first search, and backtracking. (FR-22)
- [ ] **T-32 - Write the conclusion.** Summarize what was learned about modeling a constraint-satisfaction problem in the two paradigms without making unsupported general claims. (FR-22)
- [ ] **T-33 - Prepare the final report or presentation.** Include the approach, representative code, demonstrations, results, limitations, and conclusion. (Section 8.3 of the requirements)
- [ ] **T-34 - Finish the README.** Document prerequisites, repository structure, puzzle format, test commands, demo commands, benchmark command, and report location. (NFR-02, NFR-03)
- [ ] **T-35 - Run the release checklist.** Execute every documented command from a clean shell, confirm all tests pass, validate all reported solutions, and check that referenced files exist. (NFR-01 through NFR-08)

**Exit criteria:** The codebase is reproducible, the final comparison is supported by recorded evidence, and all three deliverables are ready for submission.

## 7. Dependency Summary

| Task group | Depends on | Produces |
| --- | --- | --- |
| T-01 through T-05 | None | Working environment and fixed data contract |
| T-06 through T-13 | Foundation | Fixtures, validation, and Prolog constraint model |
| T-14 through T-18 | Prolog constraint model | Tested Prolog prototype |
| T-19 through T-25 | Shared fixtures and contract | Tested Python baseline |
| T-26 through T-28 | Both tested solvers | Reproducible comparison data |
| T-29 through T-35 | Comparison data and working code | Final report/presentation and submission-ready repository |

## 8. Definition of Done

The project is done when:

- [ ] every functional requirement has an implementation or report section;
- [ ] both automated test suites pass;
- [ ] easy and hard demonstrations work from documented commands;
- [ ] invalid and unsolvable inputs are handled distinctly;
- [ ] every returned board is independently validated;
- [ ] benchmark and source-line results can be reproduced;
- [ ] the report explains the four required course connections; and
- [ ] the repository contains no undocumented setup step required for evaluation.
