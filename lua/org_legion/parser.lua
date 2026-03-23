local M = {}

local function parse_tag_block(block)
  local tags = {}
  if not block or block == "" then
    return tags
  end
  for tag in block:gmatch(":([^:]+)") do
    if tag ~= "" then
      table.insert(tags, tag)
    end
  end
  return tags
end

local function split_headline(line)
  local stars, body = line:match("^(%*+)%s+(.-)%s*$")
  if not stars then
    return nil
  end

  local title = body
  local tag_block = nil
  local maybe_title, maybe_tags = body:match("^(.-)%s+(:[%w_@#%%:%-]+:)%s*$")
  if maybe_tags then
    title = maybe_title
    tag_block = maybe_tags
  end

  return {
    stars = stars,
    level = #stars,
    title = title,
    tag_block = tag_block,
    tags = parse_tag_block(tag_block),
  }
end

local function extract_todo(title)
  local token = title and title:match("^(%u[%u_%-]*)%f[%s]")
  return token
end

function M.parse_lines(lines)
  local nodes = {}
  local stack = {}

  for line_nr, raw in ipairs(lines) do
    local p = split_headline(raw)
    if p then
      local node = {
        index = #nodes + 1,
        line_nr = line_nr,
        level = p.level,
        stars = p.stars,
        title = p.title,
        todo = extract_todo(p.title),
        tags = p.tags,
        raw = raw,
        parent = nil,
        children = {},
        end_line = #lines,
      }

      while #stack > 0 and nodes[stack[#stack]].level >= node.level do
        local done_idx = table.remove(stack)
        nodes[done_idx].end_line = line_nr - 1
      end

      if #stack > 0 then
        node.parent = stack[#stack]
        table.insert(nodes[node.parent].children, node.index)
      end

      table.insert(nodes, node)
      table.insert(stack, node.index)
    end
  end

  while #stack > 0 do
    local done_idx = table.remove(stack)
    nodes[done_idx].end_line = #lines
  end

  return nodes
end

function M.build_line_with_tags(node, ordered_tags)
  local out = node.stars .. " " .. node.title
  if #ordered_tags > 0 then
    out = out .. " :" .. table.concat(ordered_tags, ":") .. ":"
  end
  return out
end

function M.merge_tags(node, desired_derived, derived_set)
  local user_tags = {}
  local seen = {}

  for _, tag in ipairs(node.tags) do
    if not derived_set[tag] and not seen[tag] then
      table.insert(user_tags, tag)
      seen[tag] = true
    end
  end

  local derived_tags = {}
  for tag, enabled in pairs(desired_derived) do
    if enabled and derived_set[tag] then
      table.insert(derived_tags, tag)
    end
  end
  table.sort(derived_tags)

  for _, tag in ipairs(derived_tags) do
    if not seen[tag] then
      table.insert(user_tags, tag)
      seen[tag] = true
    end
  end

  return user_tags
end

return M
