"""Read and print the shared Sudoku fixture format."""

from pathlib import Path


def load_puzzle(path: str | Path) -> list[list[int]]:
    """Read compact or whitespace-separated rows from a fixture file.

    Invalid tokens remain strings for validate_puzzle to reject.
    """
    rows = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        tokens = line.split()
        if len(tokens) == 1 and len(tokens[0]) == 9:
            tokens = list(tokens[0])
        row = []
        for token in tokens:
            try:
                row.append(int(token))
            except ValueError:
                row.append(token)
        rows.append(row)
    return rows


def print_board(board: list[list[int]]) -> None:
    """Print nine compact digit rows."""
    for row in board:
        print("".join(map(str, row)))
