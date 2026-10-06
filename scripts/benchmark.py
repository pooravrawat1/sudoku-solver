"""Measure both solvers on the same fixtures and save reproducible CSVs."""

import argparse
import csv
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import platform
import statistics
import subprocess
import sys
from time import perf_counter_ns

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src" / "python"))

from count_lines import source_line_rows
from puzzle_io import load_puzzle
from sudoku import is_solution, solve


PUZZLES = ("easy", "hard")
RAW_FIELDS = ("puzzle", "implementation", "run", "elapsed_ms", "validated", "solution")
SUMMARY_FIELDS = ("puzzle", "implementation", "runs", "median_ms", "minimum_ms", "maximum_ms")


def prolog_version() -> str:
    result = subprocess.run(["swipl", "--version"], capture_output=True, text=True, check=True)
    return result.stdout.strip()


def run_prolog(process: subprocess.Popen[str], name: str) -> tuple[float, list[list[int]]]:
    assert process.stdin is not None and process.stdout is not None
    process.stdin.write(f"{name}\n")
    process.stdin.flush()
    first_line = process.stdout.readline().strip()
    if not first_line:
        raise RuntimeError("Prolog benchmark worker stopped before returning a duration")
    elapsed_ms = float(first_line) * 1000
    first_row = process.stdout.readline().strip()
    if first_row == "unsolvable":
        raise RuntimeError(f"Prolog could not solve the {name} benchmark fixture")
    rows = [first_row] + [process.stdout.readline().strip() for _ in range(8)]
    if any(len(row) != 9 or not row.isdigit() for row in rows):
        raise RuntimeError(f"Prolog benchmark worker returned an invalid board: {rows!r}")
    return elapsed_ms, [[int(value) for value in row] for row in rows]


def run_python(puzzle: list[list[int]]) -> tuple[float, list[list[int]] | None]:
    start = perf_counter_ns()
    solution = solve(puzzle)
    elapsed_ms = (perf_counter_ns() - start) / 1_000_000
    return elapsed_ms, solution


def write_csv(path: Path, fields: tuple[str, ...], rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runs", type=int, default=7, help="recorded runs per puzzle and solver")
    parser.add_argument("--warmups", type=int, default=1, help="runs excluded from the CSV and median")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "reports" / "benchmark")
    args = parser.parse_args()
    if args.runs < 1 or args.warmups < 1:
        parser.error("--runs and --warmups must each be at least 1")

    puzzles = {name: load_puzzle(ROOT / "data" / "puzzles" / f"{name}.txt")
               for name in PUZZLES}
    raw_rows = []
    summary_rows = []
    command = ["swipl", "-q", "-s", "scripts/benchmark_prolog.pl"]
    with subprocess.Popen(
        command, cwd=ROOT, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, text=True, bufsize=1,
    ) as prolog:
        for name, puzzle in puzzles.items():
            for implementation in ("prolog", "python"):
                recorded = []
                for trial in range(args.warmups + args.runs):
                    if implementation == "prolog":
                        elapsed_ms, solution = run_prolog(prolog, name)
                    else:
                        elapsed_ms, solution = run_python(puzzle)
                    validated = solution is not None and is_solution(puzzle, solution)
                    if not validated:
                        raise RuntimeError(f"{implementation} returned an invalid {name} result")

                    measured = trial >= args.warmups
                    if measured:
                        recorded.append(elapsed_ms)
                        raw_rows.append({
                            "puzzle": name,
                            "implementation": implementation,
                            "run": trial - args.warmups + 1,
                            "elapsed_ms": f"{elapsed_ms:.6f}",
                            "validated": validated,
                            "solution": "".join(str(value) for row in solution for value in row),
                        })

                summary_rows.append({
                    "puzzle": name,
                    "implementation": implementation,
                    "runs": args.runs,
                    "median_ms": f"{statistics.median(recorded):.6f}",
                    "minimum_ms": f"{min(recorded):.6f}",
                    "maximum_ms": f"{max(recorded):.6f}",
                })
        assert prolog.stdin is not None
        prolog.stdin.close()
        if prolog.wait() != 0:
            assert prolog.stderr is not None
            raise RuntimeError(prolog.stderr.read())

    output = args.output_dir
    output.mkdir(parents=True, exist_ok=True)
    write_csv(output / "raw.csv", RAW_FIELDS, raw_rows)
    write_csv(output / "summary.csv", SUMMARY_FIELDS, summary_rows)
    write_csv(output / "source_lines.csv",
              ("implementation", "file", "source_lines"), source_line_rows())

    environment = {
        "recorded_at_utc": datetime.now(timezone.utc).isoformat(),
        "system": platform.system(),
        "system_release": platform.release(),
        "machine": platform.machine(),
        "processor": platform.processor() or platform.machine(),
        "logical_cpu_count": os.cpu_count(),
        "python_version": platform.python_version(),
        "prolog_version": prolog_version(),
        "puzzles": list(PUZZLES),
        "warmups_per_case": args.warmups,
        "measured_runs_per_case": args.runs,
        "python_timing": "time.perf_counter_ns around solve(board) in one Python process",
        "prolog_timing": "get_time around once(solve(Puzzle, Solution)) in one persistent Prolog process",
        "fixture_loading_timed": False,
        "process_startup_timed": False,
        "summary_statistic": "median of measured runs in milliseconds",
        "validation": "Every warm-up and measured result checked with Python is_solution",
        "line_count_command": "python3 scripts/count_lines.py",
        "line_count_rule": "exclude blank and comment-only lines; count solver modules only",
    }
    (output / "environment.json").write_text(
        json.dumps(environment, indent=2) + "\n", encoding="utf-8"
    )

    for row in summary_rows:
        print(f"{row['puzzle']}: {row['implementation']} median {row['median_ms']} ms"
              f" ({row['runs']} runs)")
    print(f"Saved raw timings, summary, environment, and line counts to {output}")


if __name__ == "__main__":
    main()
