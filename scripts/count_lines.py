"""Count nonblank, non-comment-only lines in the two solver modules."""

import csv
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCES = (
    ("prolog", "src/prolog/sudoku.pl", "%"),
    ("python", "src/python/sudoku.py", "#"),
)


def count_source_lines(path: Path, comment_prefix: str) -> int:
    """Count lines after excluding blanks and full-line comments."""
    count = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith(comment_prefix):
            count += 1
    return count


def source_line_rows() -> list[dict[str, str | int]]:
    return [
        {
            "implementation": implementation,
            "file": filename,
            "source_lines": count_source_lines(ROOT / filename, comment),
        }
        for implementation, filename, comment in SOURCES
    ]


def main() -> None:
    writer = csv.DictWriter(sys.stdout, fieldnames=("implementation", "file", "source_lines"))
    writer.writeheader()
    writer.writerows(source_line_rows())


if __name__ == "__main__":
    main()
