#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "${script_dir}/../../../.." && pwd)"

cd "${project_root}"

if ! command -v rg >/dev/null 2>&1; then
    echo "error: ripgrep (rg) is required to discover Prolog files" >&2
    exit 127
fi

prolog_files=()
while IFS= read -r file; do
    prolog_files+=("${file}")
done < <(rg --files src tests -g '*.pl' 2>/dev/null | sort)

if [[ ${#prolog_files[@]} -eq 0 ]]; then
    echo "No Prolog files found under src/ or tests/."
    exit 0
fi

if ! command -v swipl >/dev/null 2>&1; then
    echo "error: SWI-Prolog (swipl) is not installed or is not on PATH" >&2
    exit 127
fi

log_file="$(mktemp "${TMPDIR:-/tmp}/sudoku-prolog-check.XXXXXX")"
trap 'rm -f "${log_file}"' EXIT

for file in "${prolog_files[@]}"; do
    echo "Compiling ${file}"
    : >"${log_file}"

    if ! swipl -q -t halt -s "${file}" 2>"${log_file}"; then
        cat "${log_file}" >&2
        exit 1
    fi

    if [[ -s "${log_file}" ]]; then
        cat "${log_file}" >&2
    fi

    if rg --quiet '^Warning:' "${log_file}"; then
        echo "error: compiler warning found in ${file}" >&2
        exit 1
    fi
done

test_files=()
while IFS= read -r file; do
    test_files+=("${file}")
done < <(rg --files tests/prolog -g 'test_*.pl' 2>/dev/null | sort)

if [[ ${#test_files[@]} -gt 0 ]]; then
    echo "Running plunit tests"
    swipl -q -g run_tests -t halt "${test_files[@]}"
else
    echo "No plunit test files found under tests/prolog/."
fi

echo "Prolog checks passed."
