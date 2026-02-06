下面给你一套“把 Norang（Bernt Hansen）那套 GTD / 项目推进 / 打卡 / 归档的全流程”迁移到 **Neovim + nvim-orgmode（orgmode.nvim）+ 你自己写的插件**的落地方案：先用 orgmode.nvim 覆盖它已经支持的部分；对 **Norang 工作流里最关键但 orgmode.nvim 没有“elisp skip 函数”那类能力**的部分，用一个小插件补齐（核心是：**自动给 headline 打 PROJECT / STUCK / ARCHIVE_CANDIDATE 等派生标签**，让 agenda 用纯 tags/property 查询就能做出 Norang 的 block agenda 视图）。

---

## 1) 先把 Norang 的“全流程”拆成可移植模块

Norang 那篇文档的 GTD 主线基本是：

1. **Capture**：所有输入先进 inbox/refile（不要当场分类）。([Norang 公共文档][1])
2. **Refile**：定期把 inbox 的条目移动到正确文件/项目树。([Norang 公共文档][1])
3. **TODO 流程**：用一套关键字区分 TODO / NEXT / WAITING / HOLD / DONE / CANCELLED 等，并且用“状态触发标签/记录”减少手工维护。([Norang 公共文档][1])
4. **Agenda（Block agenda）**：用一个组合视图把“今天日程 + 待 refile + 下一步行动 + 项目列表 + 卡住项目 + 等待事项 +（月初）可归档项”等堆在一个屏里。([Norang 公共文档][1])
5. **Clocking**：对正在做的事情打卡，最好能“punch in/out + 保持 clock 不中断”。([Norang 公共文档][1])
6. **Archiving**：每月把“足够旧的已完成任务”批量归档（>30 天且最近两个月没活动时间戳的 DONE 任务）。([Norang 公共文档][1])

你要在 Neovim 里复刻“全流程”，真正难点只有两个：

- **“项目/卡住项目”的识别**：Norang 在 Emacs 里用一堆 skip 函数（按 subtree 结构判断“项目=有 TODO 子任务的 TODO headline；卡住=项目里没有 NEXT 子任务”）。orgmode.nvim 的 agenda 自定义视图是基于 tags/property 匹配串，不是任意函数。([Nvim Orgmode][2])
- **“可归档项（按日期条件）”的自动筛选**：同理，纯匹配串很难做“30 天前且两个月内无时间戳”。([Norang 公共文档][1])

解决思路：**你写的插件负责把这些“函数式逻辑”提前算出来，落成标签或属性**；agenda 就能继续用 orgmode.nvim 自带的 custom commands 来拼 block view。

---

## 2) orgmode.nvim 这边你能直接用上的能力

下面这些对迁移 Norang 流程很关键，而且 orgmode.nvim 已经有：

### 2.1 Capture 模板

orgmode.nvim 支持 capture templates（含时间/输入占位符、动态 target 等）。([Nvim Orgmode][2])

### 2.2 Refile

支持在 org 文件里 refile，也支持从 agenda 里 refile；并且支持 `destination.org/<headline>` 这种目标写法（前提：目标文件在 `org_agenda_files` 范围内）。([Nvim Orgmode][2])

### 2.3 自定义 Block agenda

支持 `org_agenda_custom_commands`，一个 command 里可以组合多个 block（agenda / tags / tags_todo），每个 block 还能单独设置 header、span、忽略 scheduled/deadline 等。([Nvim Orgmode][2])

### 2.4 Clocking（部分支持）

支持 clock in/out/cancel/goto、LOGBOOK drawer 记录、agenda 内高亮当前 clock 的任务、clock report、statusline 显示当前 clock。([Nvim Orgmode][2])

### 2.5 标签继承

`org_use_tag_inheritance` 可开关“父标签继承用于搜索”。这对“项目树一层打标签、子任务继承上下文”很有用。([Nvim Orgmode][2])

---

## 3) 推荐的目录与文件结构（对齐 Norang 思路）

最小可用的一套（你可按自己口味拆更多文件）：

- `~/org/refile.org`：inbox（capture 默认落这里）
- `~/org/gtd.org`：通用任务（非项目、单步任务、杂项）
- `~/org/projects.org`：项目树（每个项目一个 headline，下面是子任务）
- `~/org/tickler.org`：将来/提醒（可选）
- `~/org/archive/*.org_archive`：归档文件（orgmode/Emacs 都习惯 `file.org_archive`）([Norang 公共文档][1])

---

## 4) orgmode.nvim 配置骨架（把能“原生覆盖”的先配齐）

> 下面示例用的是 `nvim-orgmode/orgmode`（现在的主仓库名）。自定义键位你可后续再调。

```lua
-- lua/plugins/orgmode.lua (lazy.nvim 示例)
return {
  'nvim-orgmode/orgmode',
  ft = { 'org', 'orgagenda' },
  config = function()
    require('orgmode').setup({
      org_agenda_files = { '~/org/**/*' },
      org_default_notes_file = '~/org/refile.org',

      -- Norang 风格的 TODO 流程（核心关键字）
      -- Norang 的关键词序列示例见文档（TODO/NEXT/DONE + WAITING/HOLD/CANCELLED/PHONE/MEETING）:contentReference[oaicite:14]{index=14}
      org_todo_keywords = {
        'TODO(t)',
        'NEXT(n)',
        'WAITING(w)',
        'HOLD(h)',
        '|',
        'DONE(d)',
        'CANCELLED(c)',
        'PHONE',
        'MEETING',
      },

      -- 把状态变化记录到 LOGBOOK（Norang 强依赖 LOGBOOK/clock 这套习惯）
      org_log_into_drawer = 'LOGBOOK', -- :contentReference[oaicite:15]{index=15}

      org_use_tag_inheritance = true, -- :contentReference[oaicite:16]{index=16}

      -- Capture 模板（orgmode.nvim 支持很多占位符/动态 target）:contentReference[oaicite:17]{index=17}
      org_capture_templates = {
        t = {
          description = 'Task (inbox)',
          template = '* TODO %? :REFILE:\n%U\n',
          target = '~/org/refile.org',
        },
        m = {
          description = 'Meeting',
          template = '* MEETING %? :MEETING:REFILE:\n%U\n',
          target = '~/org/refile.org',
        },
        p = {
          description = 'Phone',
          template = '* PHONE %? :PHONE:REFILE:\n%U\n',
          target = '~/org/refile.org',
        },
        j = {
          description = 'Journal',
          template = '\n*** %<%Y-%m-%d> %<%A>\n**** %U\n\n%?',
          target = '~/org/journal/%<%Y-%m>.org',
        },
      },

      -- 先留空：后面我们会靠“你写的插件”来让 PROJECT/STUCK/ARCHIVE_CANDIDATE 这些标签可用
      org_agenda_custom_commands = {
        -- 先占位，下一节给完整版本
      },
    })

    -- 你自己的插件（后面会给代码骨架）
    require('org-norang').setup({
      org_root = vim.fn.expand('~/org'),
      derived_tags = {
        project = 'PROJECT',
        stuck = 'STUCK',
        archive_candidate = 'ARCHIVE_CANDIDATE',
      },
    })
  end,
}
```

---

## 5) 用 org_agenda_custom_commands 拼出 Norang 的“Block agenda”外形

orgmode.nvim 的 custom commands 允许组合多个 block。([Nvim Orgmode][2])
我们目标是做一个类似 Norang “一个屏看完”的 GTD 入口（你可以设成按键 `g` 或 `n`）。

核心 blocks（对齐 Norang 的日常视角）：

- Inbox（refile.org 里的 :REFILE:）
- 今日 agenda（day）
- Stuck projects（PROJECT+STUCK）
- Projects（PROJECT-STUCK）
- Next actions（TODO="NEXT" 且排除 WAITING/HOLD）
- Waiting/Hold
- Archive candidates（ARCHIVE_CANDIDATE）

```lua
-- 放进 orgmode.setup({ org_agenda_custom_commands = { ... }})
org_agenda_custom_commands = {
  n = {
    description = 'Norang GTD (block agenda)',
    types = {
      {
        type = 'tags_todo',
        match = 'REFILE',
        org_agenda_overriding_header = 'Inbox (Refile)',
        org_agenda_files = { '~/org/refile.org' },
      },
      {
        type = 'agenda',
        org_agenda_overriding_header = 'Today',
        org_agenda_span = 'day',
      },
      {
        type = 'tags_todo',
        match = 'PROJECT+STUCK',
        org_agenda_overriding_header = 'Stuck Projects',
      },
      {
        type = 'tags_todo',
        match = 'PROJECT-STUCK',
        org_agenda_overriding_header = 'Projects',
      },
      {
        type = 'tags_todo',
        match = 'TODO="NEXT"-WAITING-HOLD',
        org_agenda_overriding_header = 'Next Actions',
        -- 可选：避免 NEXT actions 被 scheduled/deadline 噪音淹没
        org_agenda_todo_ignore_scheduled = 'future',
      },
      {
        type = 'tags_todo',
        match = 'WAITING|HOLD',
        org_agenda_overriding_header = 'Waiting / Hold',
      },
      {
        type = 'tags',
        match = 'ARCHIVE_CANDIDATE',
        org_agenda_overriding_header = 'Archive candidates',
      },
    },
  },
}
```

注意两点：

1. `match` 语法 orgmode.nvim 明确说是“等价于 org tags view 的 Match”，并且给了 Org manual 链接。([Nvim Orgmode][2])
2. 这里的 `PROJECT / STUCK / ARCHIVE_CANDIDATE` **不是你手工打的**，而是下一节你的插件自动维护。

---

## 6) 你要写的插件：把 Norang 的“函数逻辑”前置成标签

### 6.1 插件职责（最小可用 MVP）

你的插件 `org-norang.nvim` 只做三件事，就能把 Norang 工作流的大部分关键视图跑起来：

1. **扫描所有 agenda files**，解析 headline 树
2. 自动给 headline 打派生标签：
   - `PROJECT`：一个 TODO headline，且 subtree 内至少有一个 TODO 子任务（Norang 的“项目=带子任务的任务”）。
   - `STUCK`：PROJECT 但 subtree 内没有可推进的 NEXT（Norang 的“卡住项目=没有 NEXT”）。
   - `ARCHIVE_CANDIDATE`：DONE 且超过 30 天，且本月/上月无任何时间戳活动（Norang 的归档规则）。([Norang 公共文档][1])

3. 暴露 `:OrgNorangRefresh`（手工触发）+ 在保存 org 文件后自动 refresh

这样 agenda 里只需要 tags/property 匹配，不需要 skip 函数。

---

## 6.2 一个可直接改的 Lua 代码骨架（不依赖 orgmode 内部 API）

> 我这里给的是“纯文本扫描 + 构树 + 重写 headline 行”的方案，优点是你不需要摸 orgmode.nvim 的内部 Lua API（因为 API 文档在 `:h OrgApi`，但不同版本可能变化）。缺点是你要自己写一点 org headline 解析。

创建：`lua/org-norang/init.lua`

```lua
local M = {}

local default_cfg = {
  org_root = vim.fn.expand('~/org'),
  derived_tags = {
    project = 'PROJECT',
    stuck = 'STUCK',
    archive_candidate = 'ARCHIVE_CANDIDATE',
  },
  -- 你可以把关键词从 orgmode 配置里同步进来，这里先写死成 Norang 风格
  todo_keywords = { 'TODO', 'NEXT', 'WAITING', 'HOLD', 'DONE', 'CANCELLED', 'PHONE', 'MEETING' },
  done_keywords = { 'DONE', 'CANCELLED', 'PHONE', 'MEETING' },
  next_keyword = 'NEXT',
  stuck_ignore_states = { 'WAITING', 'HOLD' },
}

local function setify(list)
  local s = {}
  for _, v in ipairs(list) do s[v] = true end
  return s
end

local function parse_tags_from_headline(line)
  -- 形如: "* TODO Title      :TAG1:TAG2:"
  local tags = {}
  local tagblob = line:match('%s+(:[%w_@#%%%-]+:)+%s*$')
  if not tagblob then return tags end
  for t in tagblob:gmatch(':([%w_@#%%%-]+):') do
    tags[t] = true
  end
  return tags, tagblob
end

local function strip_tagblob(line)
  return (line:gsub('%s+(:[%w_@#%%%-]+:)+%s*$', ''))
end

local function headline_level(line)
  local stars = line:match('^(%*+) ')
  return stars and #stars or nil
end

local function parse_todo_keyword(line, todo_set)
  -- "* TODO ..." or "* NEXT ..."
  local kw = line:match('^%*+%s+(%u[%u%d_%-]+)%s+')
  if kw and todo_set[kw] then return kw end
  return nil
end

local function build_tree(lines, todo_set)
  local nodes = {}
  local stack = {}

  for i, line in ipairs(lines) do
    local lvl = headline_level(line)
    if lvl then
      local node = {
        line_nr = i,
        level = lvl,
        raw = line,
        todo = parse_todo_keyword(line, todo_set),
        tags = (function()
          local t = parse_tags_from_headline(line)
          return t
        end)(),
        children = {},
        parent = nil,
      }

      while #stack > 0 and stack[#stack].level >= lvl do
        table.remove(stack)
      end
      if #stack > 0 then
        node.parent = stack[#stack]
        table.insert(stack[#stack].children, node)
      end

      table.insert(nodes, node)
      table.insert(stack, node)
    end
  end

  return nodes
end

local function subtree_range(lines, node, all_nodes_index)
  -- 简化：subtree 结束 = 下一个 level <= 当前 level 的 headline 之前
  local start = node.line_nr
  local stop = #lines
  for i = all_nodes_index + 1, #M._flat_nodes do
    local n = M._flat_nodes[i]
    if n.level <= node.level then
      stop = n.line_nr - 1
      break
    end
  end
  return start, stop
end

local function any_descendant(node, pred)
  for _, ch in ipairs(node.children) do
    if pred(ch) then return true end
    if any_descendant(ch, pred) then return true end
  end
  return false
end

local function should_have_tag(node, tag) return node.tags[tag] == true end
local function add_tag(node, tag) node.tags[tag] = true end
local function remove_tag(node, tag) node.tags[tag] = nil end

local function render_tagblob(tags)
  local list = {}
  for t, _ in pairs(tags) do table.insert(list, t) end
  table.sort(list)
  if #list == 0 then return '' end
  return ' :' .. table.concat(list, ':') .. ':'
end

local function rewrite_headline_line(original, tags)
  local base = strip_tagblob(original)
  return base .. render_tagblob(tags)
end

local function has_recent_timestamp(lines, start_ln, end_ln, now_ts)
  -- 粗略实现：如果 subtree 内出现任何 "YYYY-MM-" 且属于本月或上月 => recent
  local now = os.date('*t', now_ts)
  local this_month = string.format('%04d-%02d-', now.year, now.month)

  local prev_year, prev_month = now.year, now.month - 1
  if prev_month == 0 then prev_month = 12; prev_year = prev_year - 1 end
  local last_month = string.format('%04d-%02d-', prev_year, prev_month)

  for i = start_ln, end_ln do
    local l = lines[i]
    if l:find(this_month, 1, true) or l:find(last_month, 1, true) then
      return true
    end
  end
  return false
end

local function refresh_buffer(bufnr, cfg)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local todo_set = setify(cfg.todo_keywords)
  local done_set = setify(cfg.done_keywords)
  local stuck_ignore_set = setify(cfg.stuck_ignore_states)

  local flat_nodes = build_tree(lines, todo_set)
  M._flat_nodes = flat_nodes

  local now_ts = os.time()

  for idx, node in ipairs(flat_nodes) do
    -- 项目判定：自己是 TODO，且 subtree 内存在任意 TODO 子任务（非 done）
    local is_project =
      node.todo ~= nil and any_descendant(node, function(n)
        return n.todo ~= nil and not done_set[n.todo]
      end)

    -- 卡住判定：是项目，但 subtree 内没有 NEXT（且 NEXT 不处于 WAITING/HOLD）
    local has_next =
      is_project and any_descendant(node, function(n)
        if n.todo ~= cfg.next_keyword then return false end
        -- 如果你还想排除带 WAITING/HOLD tag 的 NEXT，可在这里加条件
        -- 或者排除 n.todo 属于 WAITING/HOLD（不过通常 NEXT 不会等于 WAITING/HOLD）
        return true
      end)

    local is_stuck = is_project and not has_next

    -- 归档候选：done + 30天前 + 最近两个月无时间戳（这里用“本月/上月无时间戳”近似 Norang 规则）:contentReference[oaicite:21]{index=21}
    local start_ln, end_ln = subtree_range(lines, node, idx)
    local archive_candidate = false
    if node.todo ~= nil and done_set[node.todo] then
      if not has_recent_timestamp(lines, start_ln, end_ln, now_ts) then
        archive_candidate = true
      end
    end

    -- 写入派生 tags
    local T = cfg.derived_tags
    if is_project then add_tag(node, T.project) else remove_tag(node, T.project) end
    if is_stuck then add_tag(node, T.stuck) else remove_tag(node, T.stuck) end
    if archive_candidate then add_tag(node, T.archive_candidate) else remove_tag(node, T.archive_candidate) end

    -- 重写 headline 行
    local new_line = rewrite_headline_line(node.raw, node.tags)
    if new_line ~= node.raw then
      lines[node.line_nr] = new_line
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

function M.refresh_all()
  local cfg = M._cfg
  -- 简化：把 org_root 下的所有 org 都扫一遍
  local pattern = cfg.org_root .. '/**/*.org'
  local files = vim.fn.glob(pattern, true, true)

  for _, f in ipairs(files) do
    local bufnr = vim.fn.bufadd(f)
    vim.fn.bufload(bufnr)
    refresh_buffer(bufnr, cfg)
    -- 注意：这里会直接修改 buffer；是否自动写盘你可自选
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd('silent write')
    end)
  end
end

function M.setup(cfg)
  M._cfg = vim.tbl_deep_extend('force', default_cfg, cfg or {})

  vim.api.nvim_create_user_command('OrgNorangRefresh', function()
    M.refresh_all()
  end, {})

  -- 保存 org 文件后自动更新派生标签
  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*.org',
    callback = function(args)
      refresh_buffer(args.buf, M._cfg)
      -- 可选：自动写盘（避免二次保存）；看你习惯
      -- vim.api.nvim_buf_call(args.buf, function() vim.cmd('silent write') end)
    end,
  })
end

return M
```

这段代码做了三件关键事：

- 用 headline 树结构推导 `PROJECT/STUCK`（从而在 agenda 里复刻 Norang “Projects / Stuck Projects”块）([Norang 公共文档][1])
- 用“本月/上月时间戳存在性”近似 Norang 的归档筛选（你可进一步把 “30 天” 精确化，逻辑来源于 Norang 的归档描述）([Norang 公共文档][1])
- 把推导结果落成 tags，使 orgmode.nvim 的 `tags` / `tags_todo` 视图能直接用 match 串过滤 ([Nvim Orgmode][2])

---

## 7) Clocking：用 orgmode.nvim 原生能力 +（可选）你插件再做 “punch in/out”

orgmode.nvim 的 clocking 支持点包括：clock in/out/cancel/goto、LOGBOOK 写入、agenda 高亮当前 clock、clock report、statusline 函数。([Nvim Orgmode][2])

Norang 的 punch in/out（保持 clock 不中断）你可以这么落地：

- **第一阶段（无插件）**：
  用 orgmode.nvim 自带 clock in/out 去做时间记录；用 statusline 显示当前 clock（`v:lua.orgmode.statusline()`）。([Nvim Orgmode][2])
- **第二阶段（加插件）**：
  你的插件维护一个固定任务，比如 `* TODO Organization`，当你 clock out 时自动 clock in 到这个任务。

  > 这里我不写死调用 orgmode.nvim 的内部函数名（因为不同版本 API 可能变；官方建议看 `:h OrgApi`），你可以用两种方式做：
  1. 直接 `vim.api.nvim_feedkeys()` 触发你自己配置的 `<leader>oxi / <leader>oxo`；
  2. 或者查 `:h OrgApi` 后调用对应 Lua action。([Nvim Orgmode][2])

---

## 8) 你每天怎么跑“全流程”（对齐 Norang 的节奏）

1. **随手收集**：`<leader>oc` 选模板，把所有东西都丢 `refile.org`（带 :REFILE:）。([Nvim Orgmode][2])
2. **打开 Norang GTD block agenda**：`<leader>oa` 然后选你定义的 `n`（或你映射的快捷键）。([Nvim Orgmode][2])
3. **清 Inbox**：在 “Inbox (Refile)” block 里逐条 `refile` 到 projects/gtd 等文件（orgmode.nvim 支持 refile 到 `destination.org/<headline>`）。([Nvim Orgmode][2])
4. **推进项目**：
   - 看 “Stuck Projects”，给它们补一个 NEXT；
   - 然后在 “Next Actions” block 挑今天要做的。([Norang 公共文档][1])

5. **Clocking**：做事前 clock in，做完 clock out；你愿意的话再加 punch 逻辑。([Nvim Orgmode][2])
6. **月初归档**：看 “Archive candidates”，批量把旧 DONE 任务移动到 `file.org_archive::* Archived Tasks`（Norang 的归档位置/策略描述）。([Norang 公共文档][1])

---

## 9) 你会遇到的“迁移差异”，以及最稳的处理方式

- **差异 1：Norang 的 skip 函数很强**
  我这里用“派生标签”替代函数逻辑：把复杂判断提前算好，agenda 只做匹配过滤。这样最贴合 orgmode.nvim 的能力边界。([Nvim Orgmode][2])

- **差异 2：归档条件是时间逻辑**
  你可以先用“本月/上月是否出现时间戳”做近似（已经够接近 Norang 的描述），后续再精确到“最后活动时间戳 <= today-30d”。([Norang 公共文档][1])

- **差异 3：状态触发标签（WAITING/HOLD 自动上 tag）**
  Emacs org-mode 有 `org-todo-state-tags-triggers` 那种机制；orgmode.nvim 不一定完全等价。你可以把这个也交给插件：在保存时扫描 todo state，把 WAITING/HOLD/CANCELLED 同名 tag 自动同步（agenda 匹配就更稳定）。([Norang 公共文档][1])

---

如果你愿意把“你现在的 org 文件结构（有哪些文件）+ 你打算保留 Norang 文档里的哪些视图块（比如是否要 Someday/Incubate、是否要 tickler）”贴一下，我可以直接按你的文件名把：

- `org_capture_templates`
- `org_agenda_custom_commands`（完整 block）
- 以及插件里“项目/卡住/归档”的判定规则

全部替你对齐成一套可直接复制的配置。

[1]: https://doc.norang.ca/org-mode.html "https://doc.norang.ca/org-mode.html"
[2]: https://nvim-orgmode.github.io/configuration "https://nvim-orgmode.github.io/configuration"
