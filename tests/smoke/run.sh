#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORGMODE_RTP="${ORGMODE_RTP:-$ROOT_DIR/.tests/deps/orgmode}"
ALLOW_UNPINNED_ORGMODE="${ALLOW_UNPINNED_ORGMODE:-0}"

if [[ ! -d "$ORGMODE_RTP" ]]; then
	if [[ "$ALLOW_UNPINNED_ORGMODE" == "1" && -d "$HOME/.local/share/nvim/lazy/orgmode" ]]; then
		ORGMODE_RTP="$HOME/.local/share/nvim/lazy/orgmode"
		echo "WARN: using unpinned orgmode runtimepath: $ORGMODE_RTP" >&2
	else
		echo "orgmode runtimepath not found: $ORGMODE_RTP" >&2
		echo "Refusing unpinned fallback. Set ALLOW_UNPINNED_ORGMODE=1 to opt in." >&2
		exit 1
	fi
fi

RTP_SETUP_LUA="local function safe_path(name) local p=vim.fn.getenv(name); if type(p)~='string' or p=='' then error(name .. ' is empty') end; if p:find('[|\\r\\n\\t]') then error(name .. ' contains forbidden characters') end; if vim.fn.isdirectory(p)~=1 then error(name .. ' is not a directory: ' .. p) end; return p end; vim.opt.rtp:append(safe_path('ORGMODE_RTP')); vim.opt.rtp:append(safe_path('SMOKE_ROOT_DIR'))"

CASES=(
	punch_in_requires_id
	punch_in_clocks_default_task
	punch_in_preserves_current_buffer
	punch_out_preserves_current_buffer
	clock_out_preserves_view_state
	clock_in_todo_task_switches_to_next
	clock_in_next_project_switches_to_todo
	clock_in_preserves_view_state
	clock_out_removes_zero_duration_clock
	clock_out_in_punch_mode_returns_to_parent
	clock_out_in_punch_mode_returns_to_default
	norang_refresh_marks_stuck_project
	norang_cleanup_apply_removes_derived_tags
	capture_clock_handoff_resumes_previous
	capture_pre_refile_injects_clock_line
	todo_state_tag_triggers_norang
	norang_e2e_integrated_flow
)

for case_name in "${CASES[@]}"; do
	echo "==> smoke: ${case_name}"
	ORGMODE_RTP="$ORGMODE_RTP" SMOKE_ROOT_DIR="$ROOT_DIR" nvim --headless -u NONE \
		"+lua $RTP_SETUP_LUA" \
		"+lua require('tests.smoke.orgmode_smoke').run('$case_name')" \
		+"qa!"
done

echo "All smoke cases passed."
