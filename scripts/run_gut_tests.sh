#!/usr/bin/env bash
set -euo pipefail

# Wrapper to run GUT unit tests in headless mode without hanging.
# Ensures Godot imports are refreshed before executing the CLI runner.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
STAMP_FILE="${SCRIPT_DIR}/.godot/.last_headless_import"

should_run_import() {
	if [[ "${SKIP_GODOT_IMPORT:-0}" == "1" ]]; then
		return 1
	fi

	# Run import if the sentinel is missing or the project file changed after the last import.
	if [[ ! -f "${STAMP_FILE}" ]]; then
		return 0
	fi

	if [[ "${SCRIPT_DIR}/project.godot" -nt "${STAMP_FILE}" ]]; then
		return 0
	fi

	return 1
}

run_import_if_needed() {
	if should_run_import; then
		echo "[GUT] Running Godot import to refresh caches..."
		"${SCRIPT_DIR}/scripts/godot-cli.sh" --headless --import
		touch "${STAMP_FILE}"
	fi
}

run_import_if_needed

GUT_ARGS=(-gdir=res://tests/unit -gexit)
if [[ "$#" -gt 0 ]]; then
	GUT_ARGS+=("$@")
fi

exec "${SCRIPT_DIR}/scripts/godot-cli.sh" --headless -s res://addons/gut/gut_cmdln.gd -- "${GUT_ARGS[@]}"
