"""A direct backtracking solver for standard 9 x 9 Sudoku boards."""

DIGITS = set(range(1, 10))


def validate_puzzle(board: list[list[int]]) -> None:
    """Raise ValueError unless board has valid dimensions, cells, and clues."""
    if not isinstance(board, list) or len(board) != 9:
        raise ValueError("board must have nine rows")

    for row in board:
        if not isinstance(row, list) or len(row) != 9:
            raise ValueError("each row must have nine cells")
        for value in row:
            if type(value) is not int or not 0 <= value <= 9:
                raise ValueError("cells must be integers from 0 through 9")

    rows = board
    columns = [[board[row][col] for row in range(9)] for col in range(9)]
    boxes = [
        [board[row][col] for row in range(top, top + 3)
         for col in range(left, left + 3)]
        for top in range(0, 9, 3)
        for left in range(0, 9, 3)
    ]
    for unit in rows + columns + boxes:
        clues = [value for value in unit if value != 0]
        if len(clues) != len(set(clues)):
            raise ValueError("clues conflict in a row, column, or box")


def is_solution(original: list[list[int]], candidate: list[list[int]]) -> bool:
    """Check a completed board and its clues without using the search rules."""
    try:
        validate_puzzle(original)
    except ValueError:
        return False

    if not isinstance(candidate, list) or len(candidate) != 9:
        return False
    if any(not isinstance(row, list) or len(row) != 9 for row in candidate):
        return False
    if any(type(value) is not int or value not in DIGITS
           for row in candidate for value in row):
        return False

    if any(set(row) != DIGITS for row in candidate):
        return False
    if any({candidate[row][col] for row in range(9)} != DIGITS
           for col in range(9)):
        return False
    if any({candidate[row][col] for row in range(top, top + 3)
            for col in range(left, left + 3)} != DIGITS
           for top in range(0, 9, 3) for left in range(0, 9, 3)):
        return False

    return all(clue == 0 or clue == candidate[row][col]
               for row, values in enumerate(original)
               for col, clue in enumerate(values))


def solve(board: list[list[int]]) -> list[list[int]] | None:
    """Return a solved copy, or None for a valid puzzle with no solution.

    Invalid input raises ValueError. Search uses minimum remaining values:
    it visits the empty cell with the fewest legal candidates first.
    """
    validate_puzzle(board)
    working = [row.copy() for row in board]
    if not _search(working):
        return None
    if not is_solution(board, working):
        raise RuntimeError("search produced an invalid solution")
    return working


def _can_place(board: list[list[int]], row: int, col: int, value: int) -> bool:
    """Check row, column, and box before assigning one candidate."""
    if value in board[row]:
        return False
    if any(board[other_row][col] == value for other_row in range(9)):
        return False

    top = (row // 3) * 3
    left = (col // 3) * 3
    return not any(board[r][c] == value
                   for r in range(top, top + 3)
                   for c in range(left, left + 3))


def _select_empty(board: list[list[int]]) -> tuple[int, int, list[int]] | None:
    """Choose the empty cell with the fewest legal values."""
    best = None
    for row in range(9):
        for col in range(9):
            if board[row][col] != 0:
                continue
            candidates = [value for value in range(1, 10)
                          if _can_place(board, row, col, value)]
            if best is None or len(candidates) < len(best[2]):
                best = (row, col, candidates)
            if len(candidates) <= 1:
                return best
    return best


def _search(board: list[list[int]]) -> bool:
    choice = _select_empty(board)
    if choice is None:
        return True

    row, col, candidates = choice
    for value in candidates:
        board[row][col] = value
        if _search(board):
            return True
        board[row][col] = 0
    return False
