"""Run the Python solver on a named project fixture."""

import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src" / "python"))

from puzzle_io import load_puzzle, print_board
from sudoku import solve


FIXTURES = (
    "easy", "hard", "solved", "unsolvable",
    "invalid/wrong_rows", "invalid/wrong_columns",
    "invalid/non_integer", "invalid/out_of_range",
    "invalid/duplicate_row", "invalid/duplicate_column", "invalid/duplicate_box",
)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fixture", choices=FIXTURES)
    name = parser.parse_args().fixture
    puzzle = load_puzzle(ROOT / "data" / "puzzles" / f"{name}.txt")

    try:
        solution = solve(puzzle)
    except ValueError:
        print("invalid")
        return

    if solution is None:
        print("unsolvable")
    else:
        print("solved")
        print_board(solution)


if __name__ == "__main__":
    main()
