# Test Report: install-dadbod-grip-nvim

## Result

PASS with documented external dependency gap.

The Neovim configuration discovers, installs, and loads `dadbod-grip.nvim` from the worktree config. The local environment does not currently provide the `duckdb` CLI required for Parquet workflows.

## Commands

| Command | Result | Evidence |
|---|---|---|
| `nvim --headless -u NONE "+luafile lua/plugins/dadbod-grip.lua" +qa` | PASS | New plugin spec is valid Lua. |
| `env XDG_CONFIG_HOME="/home/c1/.config/nvim/.worktrees" XDG_DATA_HOME="/home/c1/.config/nvim/.worktrees/install-dadbod-grip-nvim/.xdg/data" XDG_STATE_HOME="/home/c1/.config/nvim/.worktrees/install-dadbod-grip-nvim/.xdg/state" XDG_CACHE_HOME="/home/c1/.config/nvim/.worktrees/install-dadbod-grip-nvim/.xdg/cache" NVIM_APPNAME="install-dadbod-grip-nvim" nvim --headless "+Lazy! install dadbod-grip.nvim" +qa` | PASS | lazy.nvim checked out `dadbod-grip.nvim`; `lazy-lock.json` now contains `dadbod-grip.nvim` at commit `4a2d5084112951d2f11d3a3cf6d3ea11b1256e93`. |
| Same isolated worktree env with `nvim --headless "+Lazy load dadbod-grip.nvim" "+lua assert(pcall(require, 'dadbod-grip'))" +qa` | PASS | Plugin module loads successfully after lazy loading. |
| Same isolated worktree env with `nvim --headless +qa` | PASS | Worktree Neovim config loads headlessly. |
| `duckdb --version` | FAIL, expected dependency gap | Shell returned `command not found: duckdb`; system package installation is out of scope for this task. |
| `git diff -- lazy-lock.json` after cleanup | PASS | Lockfile diff is scoped to adding only `dadbod-grip.nvim`; unrelated plugin lock updates were removed. |
| `nvim --headless -u NONE "+luafile lua/plugins/dadbod-grip.lua" +qa` after cleanup | PASS | Plugin spec still parses after lockfile cleanup. |

## Notes

- An initial verification attempt without isolated `XDG_CONFIG_HOME` loaded the main Neovim config instead of the worktree config; it was discarded as non-evidence.
- During `Lazy! install`, lazy.nvim emitted an `Invalid plugin spec` warning for a `cmd`-only spec exposed by the plugin's own package metadata. This did not block checkout, lockfile generation, module loading, or headless config loading.
- The temporary isolated `.xdg/` verification cache was removed after validation and is not part of the deliverable.
- A review pass found that `Lazy! install` had updated unrelated lock entries. Those entries were restored so the final lockfile change only adds `dadbod-grip.nvim`.

## Why These Checks

- Syntax loading proves the new Lua spec is parseable before involving lazy.nvim.
- Isolated worktree `NVIM_APPNAME` loading proves the branch configuration, not the main working tree configuration.
- `Lazy! install` plus module load proves the plugin can be installed and required.
- `duckdb --version` directly validates the known external dependency for Parquet support without installing system packages.
