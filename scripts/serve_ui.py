"""Serve the local Sudoku interface and run isolated SWI-Prolog traces."""

import argparse
from functools import lru_cache
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.parse import parse_qs, urlsplit

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src" / "python"))
from puzzle_io import load_puzzle

ASSETS = {"/": ("index.html", "text/html"),
          "/app.js": ("app.js", "text/javascript"),
          "/style.css": ("style.css", "text/css"),
          "/fonts/IBMPlexMono-Regular.ttf": ("fonts/IBMPlexMono-Regular.ttf", "font/ttf"),
          "/fonts/IBMPlexMono-SemiBold.ttf": ("fonts/IBMPlexMono-SemiBold.ttf", "font/ttf")}
FIXTURES = ("easy", "hard", "search", "solved", "unsolvable")
RULES = {
    "sudoku:valid_puzzle/1": ("sudoku", r"^valid_puzzle\(Puzzle\) :-"),
    "sudoku:zeros_to_variables/2": ("sudoku", r"^zeros_to_variables\(Puzzle, Board\) :-"),
    "sudoku:valid_solution/2": ("sudoku", r"^valid_solution\(Puzzle, Solution\) :-"),
    "clpfd:ins/2": ("clpfd", r"^Vs ins D :-"),
    "clpfd:all_distinct/1": ("clpfd", r"^all_distinct\(Ls\) :-"),
    "clpfd:labeling/2": ("clpfd", r"^labeling\(Options, Vars\) :-"),
    "clpfd:choice_order_variable/7": (
        "clpfd", r"^choice_order_variable\(step, Order, Var, Vars, Vars0, Selection, Consistency\) :-"
    ),
}


@lru_cache(maxsize=1)
def clpfd_source_path():
    """Resolve the source of the CLP(FD) implementation used by this server."""
    result = subprocess.run(
        ["swipl", "-q", "-g",
         "use_module(library(clpfd)),predicate_property(clpfd:labeling(_,_),file(F)),writeln(F),halt"],
        text=True, capture_output=True, timeout=5, check=True,
    )
    return Path(result.stdout.strip())


@lru_cache(maxsize=len(RULES))
def rule_source(name):
    """Return the literal installed clause for an allowlisted trace rule."""
    if name not in RULES:
        raise ValueError("Unknown trace rule.")
    origin, anchor = RULES[name]
    path = ROOT / "src" / "prolog" / "sudoku.pl" if origin == "sudoku" else clpfd_source_path()
    lines = path.read_text().splitlines()
    matches = [index for index, line in enumerate(lines) if re.match(anchor, line)]
    if len(matches) != 1:
        raise RuntimeError(f"Could not locate the source for {name}.")
    start = matches[0]
    end = start + 1
    while end < len(lines) and lines[end].strip() and not (
        name == "clpfd:choice_order_variable/7"
        and lines[end].startswith("choice_order_variable(")
    ):
        end += 1
    return {
        "rule": name,
        "file": "src/prolog/sudoku.pl" if origin == "sudoku" else "library(clpfd)",
        "line": start + 1,
        "source": "\n".join(lines[start:end]),
    }


def annotate_backtrack_targets(events):
    """Link undo events to the native redo that actually followed them."""
    for index, event in enumerate(events):
        if event["type"] not in ("retry", "unsolvable"):
            continue
        cursor = index - 1
        while cursor >= 0 and events[cursor]["type"] == "backtrack":
            if event["type"] == "retry":
                events[cursor]["target"] = {
                    "rule": event["rule"],
                    "cell": event["cell"],
                    "excluded": event["candidate"],
                }
            else:
                events[cursor]["target"] = {
                    "rule": "clpfd:labeling/2",
                    "exhausted": True,
                }
            cursor -= 1


def run_trace(board):
    """Bound execution time and reject malformed data before starting Prolog."""
    if (not isinstance(board, list) or len(board) != 9
            or any(not isinstance(row, list) or len(row) != 9 for row in board)
            or any(type(cell) is not int or not 0 <= cell <= 9
                   for row in board for cell in row)):
        raise ValueError("Enter a 9 × 9 board containing digits 0–9.")
    result = subprocess.run(
        ["swipl", "-q", "-s", str(ROOT / "scripts" / "trace_prolog.pl")],
        input=json.dumps({"board": board}), text=True, capture_output=True,
        timeout=15, cwd=ROOT,
    )
    if result.returncode:
        if "trace_limit" in result.stderr:
            raise ValueError("This puzzle exceeded 20,000 trace events. Try adding more clues.")
        print(result.stderr, file=sys.stderr)
        raise RuntimeError("Prolog could not complete this trace. Check the server terminal.")
    events = [json.loads(line) for line in result.stdout.splitlines() if line.strip()]
    if not events or events[-1]["type"] not in ("solved", "unsolvable", "invalid"):
        raise RuntimeError("Prolog returned an incomplete trace.")
    annotate_backtrack_targets(events)
    return {"events": events, "status": events[-1]["type"]}


class Handler(BaseHTTPRequestHandler):
    def respond(self, status, data, content_type="application/json"):
        payload = json.dumps(data).encode() if content_type == "application/json" else data
        self.send_response(status)
        self.send_header("Content-Type", content_type + "; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        request = urlsplit(self.path)
        path = request.path
        if path == "/api/puzzles":
            self.respond(200, {name: load_puzzle(ROOT / "data" / "puzzles" / f"{name}.txt")
                               for name in FIXTURES})
        elif path == "/api/rule":
            try:
                name = parse_qs(request.query).get("name", [""])[0]
                self.respond(200, rule_source(name))
            except ValueError as error:
                self.respond(404, {"error": str(error)})
            except (OSError, RuntimeError, subprocess.SubprocessError) as error:
                print(error, file=sys.stderr)
                self.respond(500, {"error": "Could not read the installed Prolog source."})
        elif path in ASSETS:
            filename, content_type = ASSETS[path]
            self.respond(200, (ROOT / "src" / "web" / filename).read_bytes(), content_type)
        else:
            self.respond(404, {"error": "Not found"})

    def do_POST(self):
        if self.path != "/api/trace":
            self.respond(404, {"error": "Not found"})
            return
        # This is a loopback application; only its own origin may submit work.
        origin = self.headers.get("Origin")
        if origin and origin != f"http://{self.headers.get('Host')}":
            self.respond(403, {"error": "Use the local interface to submit a puzzle."})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= 4096:
                raise ValueError("Invalid request size.")
            request = json.loads(self.rfile.read(length))
            if not isinstance(request, dict):
                raise ValueError("Expected a board object.")
            self.respond(200, run_trace(request.get("board")))
        except (ValueError, UnicodeDecodeError) as error:
            self.respond(400, {"error": str(error)})
        except subprocess.TimeoutExpired:
            self.respond(408, {"error": "The 15-second trace limit was reached. Try more clues."})
        except (RuntimeError, OSError) as error:
            print(error, file=sys.stderr)
            self.respond(500, {"error": str(error)})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()
    if not shutil.which("swipl"):
        parser.error("SWI-Prolog is required. Install it and ensure swipl is on PATH.")
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"Sudoku lab: http://127.0.0.1:{server.server_port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
