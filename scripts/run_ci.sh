#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

echo "[CI] Verifying Godot project loads without parse/runtime errors..."
"${SCRIPT_DIR}/scripts/godot-cli.sh" --headless --quit

echo "[CI] Running GUT unit test suite..."
"${SCRIPT_DIR}/scripts/run_gut_tests.sh" "$@"

echo "[CI] All checks passed."
