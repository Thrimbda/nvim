#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORGMODE_RTP="${ORGMODE_RTP:-$ROOT_DIR/.tests/deps/orgmode}"

if [[ ! -d "$ORGMODE_RTP" ]]; then
	if [[ -d "$HOME/.local/share/nvim/lazy/orgmode" ]]; then
		ORGMODE_RTP="$HOME/.local/share/nvim/lazy/orgmode"
	else
		echo "orgmode runtimepath not found: $ORGMODE_RTP" >&2
		exit 1
	fi
fi

CASES=(
	punch_in_requires_id
	punch_in_clocks_default_task
	punch_in_preserves_current_buffer
	punch_out_preserves_current_buffer
	clock_in_todo_task_switches_to_next
	clock_in_next_project_switches_to_todo
	clock_out_removes_zero_duration_clock
	clock_out_in_punch_mode_returns_to_default
	norang_refresh_marks_stuck_project
	norang_cleanup_apply_removes_derived_tags
	capture_clock_handoff_resumes_previous
	capture_pre_refile_injects_clock_line
)

for case_name in "${CASES[@]}"; do
	echo "==> smoke: ${case_name}"
	nvim --headless -u NONE \
		"+set rtp+=$ORGMODE_RTP" \
		"+set rtp+=$ROOT_DIR" \
		"+lua require('tests.smoke.orgmode_smoke').run('$case_name')" \
		+"qa!"
done

echo "All smoke cases passed."
