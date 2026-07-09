# Test Report

## Scope

本轮验证覆盖两个用户可见问题：

- `PHONE` / `MEETING` 作为 Norang capture done-state 后，能进入 `Tasks to Archive` 的 archive candidate 查询。
- agenda 打开前的 `org_legion refresh` 失败不再产生两条含糊 warning，并能显示失败文件与错误 code/message。

## Commands

1. Targeted smoke:

```bash
ALLOW_UNPINNED_ORGMODE=1 ORGMODE_RTP="$HOME/.local/share/nvim/lazy/orgmode" SMOKE_ROOT_DIR="$PWD" nvim --headless -u NONE "+lua ..." "+lua require('tests.smoke.orgmode_smoke').run('<case>')" +"qa!"
```

Cases:

- `agenda_block_matches_norang_baseline`
- `agenda_refresh_failure_warning_includes_details`
- `legion_refresh_failure_summary_formats_paths`
- `legion_archive_candidates_match_norang_month_boundary`
- `todo_state_tag_triggers_legion`

Result: all targeted cases passed.

2. Full smoke:

```bash
ALLOW_UNPINNED_ORGMODE=1 bash tests/smoke/run.sh
```

Result: exit code 0, `All smoke cases passed.`

Note: local pinned `.tests/deps/orgmode` is absent, so the smoke runner used its existing opt-in fallback:

```text
WARN: using unpinned orgmode runtimepath: /Users/c1/.local/share/nvim/lazy/orgmode
```

3. Whitespace check:

```bash
git diff --check
```

Result: exit code 0.

4. Formatter availability:

```bash
command -v stylua
```

Result: exit code 1, `stylua` is not installed locally.

5. Real agenda refresh diagnostic:

```bash
ALLOW_UNPINNED_ORGMODE=1 ORGMODE_RTP="$HOME/.local/share/nvim/lazy/orgmode" SMOKE_ROOT_DIR="$PWD" nvim --headless -u NONE "+lua ..." "+lua local legion=require('org_legion'); legion.setup({org_agenda_files={'~/OneDrive/cone/**/*.org'}, refresh={mode='approx', on_buf_write=false, debounce_ms=50, writeback='memory_only', refresh_unloaded_files=true}, observability={notify=false, log_level='info'}}); local s=legion.refresh_all({notify=false}); print(legion.format_refresh_summary(s))" +"qa!"
```

Result:

```text
org_legion refresh: total=22 ok=22 fail=0 skipped_conflict=0 skipped_unloaded=0
```

## Conclusion

验证通过。新增 coverage 证明了 archive completeness、failure warning details、manual refresh summary formatter 和 todo trigger cleanup 行为。
