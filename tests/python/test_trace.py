"""Exercise the actual Prolog-to-JSON boundary and replay semantics."""

from pathlib import Path
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from serve_ui import run_trace, load_puzzle
from sudoku import is_solution


@unittest.skipUnless(shutil.which("swipl"), "SWI-Prolog is required for trace tests")
class TraceTests(unittest.TestCase):
    def fixture(self, name):
        return load_puzzle(ROOT / "data" / "puzzles" / f"{name}.txt")

    def test_solved_traces_preserve_clues_and_validate(self):
        for name in ("easy", "hard", "search", "solved"):
            with self.subTest(name=name):
                board = self.fixture(name)
                result = run_trace(board)
                self.assertEqual(result["status"], "solved")
                self.assertTrue(is_solution(board, result["events"][-1]["board"]))
                stages = [e for e in result["events"] if e["type"] == "constraint"]
                self.assertEqual(len(stages), 27)

    def test_binding_and_undo_replay_reaches_solution_without_final_snapshot(self):
        board = self.fixture("search")
        events = run_trace(board)["events"]
        values = sum(board, [])
        undo_count = 0
        for event in events[:-1]:
            if "domains" in event:
                values = [domain[0] if len(domain) == 1 else 0
                          for row in event["domains"] for domain in row]
            elif event["type"] == "bind":
                self.assertEqual(values[event["cell"]], 0)
                values[event["cell"]] = event["value"]
            elif event["type"] == "backtrack":
                self.assertNotEqual(values[event["cell"]], 0)
                values[event["cell"]] = 0
                undo_count += 1
        self.assertGreater(undo_count, 0)
        self.assertEqual(values, sum(events[-1]["board"], []))

    def test_domains_only_shrink_during_constraint_posting(self):
        snapshots = [e["domains"] for e in run_trace(self.fixture("hard"))["events"]
                     if "domains" in e]
        for before, after in zip(snapshots, snapshots[1:]):
            for old_row, new_row in zip(before, after):
                for old, new in zip(old_row, new_row):
                    self.assertTrue(set(new) <= set(old))

    def test_unsolvable_is_distinct_from_invalid(self):
        self.assertEqual(run_trace(self.fixture("unsolvable"))["status"], "unsolvable")
        self.assertEqual(run_trace(self.fixture("invalid/duplicate_row"))["status"], "invalid")

    def test_malformed_input_rejected(self):
        for board in (None, [], [[0] * 9] * 8, [[True] * 9] * 9,
                      [["x"] * 9] * 9, [[10] * 9] * 9):
            with self.subTest(board=board):
                with self.assertRaises(ValueError):
                    run_trace(board)
