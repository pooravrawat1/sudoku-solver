# Sudoku Solver Requirements

## 1. Purpose

This document defines the requirements for the constraint-based Sudoku solver described in the project proposal for CSC 4330 Programming Language Concepts.

The project demonstrates the logic programming paradigm through a Prolog implementation and compares it with a conventional imperative backtracking implementation in Python.

## 2. Project Goals

The project must:

1. Build a working 9 x 9 Sudoku solver in SWI-Prolog using Constraint Logic Programming over Finite Domains (CLP(FD)).
2. Demonstrate Prolog concepts including facts, rules, queries, unification, logic-variable binding, constraint propagation, depth-first search, and backtracking.
3. Build a Python solver that uses an explicit backtracking algorithm as an imperative baseline.
4. Compare the implementations in terms of readability, source lines of code, runtime, and responsibility for search and control flow.
5. Produce a short written report or presentation that explains the results and connects them to course concepts.

## 3. Stakeholders

- **Student/developer:** implements, tests, measures, and explains both solvers.
- **Instructor/evaluator:** runs or reviews the software and evaluates the comparative study.
- **Demonstration audience:** observes example puzzles and the contrast between declarative and imperative approaches.

## 4. Assumptions

- The required puzzle type is standard 9 x 9 Sudoku with 3 x 3 subgrids.
- Puzzle data uses integers `1` through `9` for clues and `0` for an empty cell.
- Both implementations consume the same logical board representation and test fixtures.
- The Prolog implementation targets SWI-Prolog and uses `library(clpfd)`.
- The Python implementation targets a current Python 3 interpreter and should not require third-party packages.
- A local graphical demonstration interface is an optional extension to the
  original solver comparison. Puzzle generation and nonstandard variants remain
  outside scope.
- The solvers may return the first solution they find. Counting or enumerating every solution is not required.

## 5. Functional Requirements

### 5.1 Shared Behavior

- **FR-01 - Board input:** The system shall accept a board containing exactly nine rows with exactly nine integer cells per row.
- **FR-02 - Cell values:** The system shall accept `0` for an empty cell and values `1` through `9` for fixed clues.
- **FR-03 - Input validation:** The system shall reject malformed boards, values outside `0..9`, and initial clues that already violate a row, column, or 3 x 3 box rule.
- **FR-04 - Preserve clues:** A produced solution shall retain every nonzero value from the input board at its original position.
- **FR-05 - Sudoku rules:** A produced solution shall contain each value `1` through `9` exactly once in every row, column, and 3 x 3 box.
- **FR-06 - Solvable puzzle:** For a valid puzzle with a solution, the system shall return a complete solved board.
- **FR-07 - Unsolvable puzzle:** For a valid puzzle with no solution, the system shall report or return an unsolvable result without presenting a partial board as a solution.
- **FR-08 - Consistent fixtures:** The Prolog and Python implementations shall be tested with the same easy, hard, invalid, and unsolvable puzzle cases.

### 5.2 Prolog Solver

- **FR-09 - CLP(FD) dependency:** The Prolog solver shall import and use `library(clpfd)`.
- **FR-10 - Finite domains:** The solver shall constrain every unknown cell to the finite domain `1..9`.
- **FR-11 - Declarative constraints:** The solver shall express row, column, and 3 x 3 box uniqueness using CLP(FD) constraints rather than manually coded candidate loops.
- **FR-12 - Search:** After posting all constraints, the solver shall use CLP(FD) labeling to bind the remaining logic variables and obtain a concrete solution.
- **FR-13 - Query interface:** The core Prolog module shall expose a documented predicate that accepts a puzzle and produces a solution, suitable for use from the SWI-Prolog console and automated tests.

### 5.3 Python Baseline

- **FR-14 - Explicit search:** The Python solver shall implement recursive backtracking with explicit selection, candidate checking, assignment, recursive search, and rollback.
- **FR-15 - Comparable interface:** The Python module shall expose a documented function that accepts a puzzle and returns a solved board or an unsolvable result.
- **FR-16 - No solver library:** The Python baseline shall not use a constraint solver, Sudoku package, or other library that performs the search on its behalf.

### 5.4 Comparison and Demonstration

- **FR-17 - Demonstration:** The project shall include repeatable commands or examples that solve at least one easy and one hard puzzle with each implementation.
- **FR-18 - Runtime measurement:** The project shall measure both implementations on the same puzzle set and record the runtime method, runtime versions, and results.
- **FR-19 - Source comparison:** The project shall compare source lines of code using a documented counting rule that excludes blank lines and comment-only lines.
- **FR-20 - Readability analysis:** The report shall compare how clearly each implementation maps the Sudoku rules into code.
- **FR-21 - Search analysis:** The report shall explain which search responsibilities are handled by application code and which are handled by the language runtime or CLP(FD) library.
- **FR-22 - Course connection:** The report or presentation shall explicitly discuss logic programming, programming paradigms, scope and binding through unification, and Prolog's goal evaluation and backtracking.

## 6. Nonfunctional Requirements

- **NFR-01 - Correctness:** Every reported solution must pass an implementation-independent solution validator.
- **NFR-02 - Reproducibility:** Setup, test, demonstration, and benchmark commands must be documented in the repository `README.md` or the final report.
- **NFR-03 - Portability:** The software must run with documented versions of SWI-Prolog and Python 3 on a standard desktop environment.
- **NFR-04 - Maintainability:** Solver logic, input/fixture handling, tests, and benchmarking code should be separated so that a change in one area has minimal impact on the others.
- **NFR-05 - Clarity:** Predicates, functions, variables, and modules should use descriptive names, and comments should explain non-obvious decisions instead of restating the code.
- **NFR-06 - Deterministic reporting:** A benchmark record must identify the puzzle, implementation, number of runs, and summary statistic used.
- **NFR-07 - Performance:** Each required demonstration puzzle should complete in a practical classroom demonstration time on the documented test computer. No cross-language speed superiority is required.
- **NFR-08 - Testability:** Automated tests must be runnable independently for the Prolog and Python implementations.

## 7. Required Test Coverage

The test suite must cover:

1. A valid easy puzzle.
2. A valid hard puzzle.
3. An already solved valid board.
4. A valid but unsolvable puzzle.
5. Duplicate fixed values in a row.
6. Duplicate fixed values in a column.
7. Duplicate fixed values in a 3 x 3 box.
8. A board with the wrong number of rows or columns.
9. A board containing a non-integer or a value outside `0..9`.
10. Verification that all original clues remain unchanged in a returned solution.

## 8. Deliverables and Acceptance Criteria

### 8.1 Prolog Prototype

Accepted when:

- it uses SWI-Prolog CLP(FD) constraints;
- it passes all shared correctness and validation tests;
- it solves the selected easy and hard demonstration puzzles; and
- its public predicate and run command are documented.

### 8.2 Python Baseline

Accepted when:

- it implements backtracking directly without a solver dependency;
- it passes equivalent shared tests;
- it solves the same demonstration puzzles; and
- its public function and run command are documented.

### 8.3 Comparative Study

Accepted when it contains:

- the environment and measurement procedure;
- runtime and source-line results for the same puzzle set;
- a qualitative comparison of readability and control flow;
- discussion of the required course concepts;
- limitations that prevent the runtime comparison from being treated as a controlled language benchmark; and
- a conclusion supported by the collected evidence.

## 9. Out of Scope

- Sudoku puzzle generation or difficulty grading.
- A hosted web service or packaged desktop/mobile application. The local browser
  interface is included as a demonstration extension.
- Optical recognition of boards from images.
- Network services, user accounts, or persistent storage.
- Nonstandard board sizes or Sudoku variants.
- Formal proof of uniqueness for every input puzzle.
- Claims that runtime alone proves one programming paradigm is universally better.

## 10. Requirement Traceability Summary

| Project objective | Requirements |
| --- | --- |
| Working Prolog CLP(FD) solver | FR-01 through FR-13 |
| Imperative Python baseline | FR-01 through FR-08, FR-14 through FR-16 |
| Easy and hard demonstrations | FR-08, FR-17 |
| Runtime and code comparison | FR-18 through FR-21, NFR-06 |
| Programming language concepts | FR-09 through FR-12, FR-22 |
| Reliable submission | NFR-01 through NFR-08 and acceptance criteria |
