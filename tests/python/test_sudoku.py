"""Behavioral tests over the shared Sudoku fixtures."""

from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "src" / "python"))

from puzzle_io import load_puzzle
from sudoku import _can_place, is_solution, solve, validate_puzzle


FIXTURES = ROOT / "data" / "puzzles"
INVALID = (
    "wrong_rows", "wrong_columns", "non_integer", "out_of_range",
    "duplicate_row", "duplicate_column", "duplicate_box",
)


def fixture(name: str) -> list[list[int]]:
    return load_puzzle(FIXTURES / f"{name}.txt")


class SudokuTests(unittest.TestCase):
    def test_valid_fixtures(self) -> None:
        for name in ("easy", "hard", "solved", "unsolvable"):
            with self.subTest(name=name):
                validate_puzzle(fixture(name))

    def test_invalid_fixtures(self) -> None:
        for name in INVALID:
            with self.subTest(name=name):
                board = fixture(f"invalid/{name}")
                with self.assertRaises(ValueError):
                    validate_puzzle(board)
                with self.assertRaises(ValueError):
                    solve(board)

    def test_rejects_boolean_and_float_cells(self) -> None:
        for value in (True, 1.0):
            with self.subTest(value=value):
                board = [[0] * 9 for _ in range(9)]
                board[0][0] = value
                with self.assertRaises(ValueError):
                    validate_puzzle(board)

    def test_candidate_checks_each_unit(self) -> None:
        board = [[0] * 9 for _ in range(9)]
        board[0][0] = 1
        self.assertFalse(_can_place(board, 0, 4, 1))
        self.assertFalse(_can_place(board, 4, 0, 1))
        self.assertFalse(_can_place(board, 1, 1, 1))
        self.assertTrue(_can_place(board, 4, 4, 1))

    def test_easy_solution(self) -> None:
        board = fixture("easy")
        result = solve(board)
        self.assertEqual(result, fixture("solved"))
        self.assertTrue(is_solution(board, result))
        self.assertEqual(board, fixture("easy"))

    def test_hard_solution(self) -> None:
        board = fixture("hard")
        result = solve(board)
        self.assertIsNotNone(result)
        self.assertTrue(is_solution(board, result))
        self.assertEqual(board, fixture("hard"))

    def test_completed_board(self) -> None:
        board = fixture("solved")
        result = solve(board)
        self.assertEqual(result, board)
        self.assertIsNot(result, board)

    def test_valid_but_unsolvable(self) -> None:
        board = fixture("unsolvable")
        self.assertIsNone(solve(board))
        self.assertEqual(board, fixture("unsolvable"))

    def test_solution_rejects_incomplete_board(self) -> None:
        board = fixture("easy")
        self.assertFalse(is_solution(board, board))

    def test_solution_rejects_repeated_row_value(self) -> None:
        board = fixture("solved")
        invalid = [row.copy() for row in board]
        invalid[0][0] = invalid[0][1]
        self.assertFalse(is_solution([[0] * 9 for _ in range(9)], invalid))

    def test_solution_rejects_repeated_column_value(self) -> None:
        board = fixture("solved")
        invalid = [row.copy() for row in board]
        invalid[0][0], invalid[0][1] = invalid[0][1], invalid[0][0]
        self.assertFalse(is_solution([[0] * 9 for _ in range(9)], invalid))

    def test_solution_rejects_invalid_box(self) -> None:
        board = fixture("solved")
        invalid = [row.copy() for row in board]
        invalid[1], invalid[3] = invalid[3], invalid[1]
        self.assertFalse(is_solution([[0] * 9 for _ in range(9)], invalid))

    def test_solution_rejects_changed_clue(self) -> None:
        board = fixture("solved")
        other_solution = [
            [5 if value == 3 else 3 if value == 5 else value for value in row]
            for row in board
        ]
        self.assertFalse(is_solution(board, other_solution))
        self.assertTrue(is_solution([[0] * 9 for _ in range(9)], other_solution))

    def test_solution_rejects_malformed_candidate(self) -> None:
        board = fixture("solved")
        self.assertFalse(is_solution(board, board[:-1]))
        invalid = [row.copy() for row in board]
        invalid[0][0] = "x"
        self.assertFalse(is_solution(board, invalid))


if __name__ == "__main__":
    unittest.main()
