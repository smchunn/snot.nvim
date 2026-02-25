local M = {}

--- Prefix-to-snot-syntax mapping.
--- Each entry: { pattern = lua pattern, format = format string or handler }
---@type table<string, { key: string?, raw: boolean? }>
local PREFIX_MAP = {
  ["#"] = { key = "tag" },
  ["~"] = { key = "~" }, -- fuzzy title search, passed as-is
  ["*"] = { key = "content" },
  ["@"] = { key = "links_to" },
  ["^"] = { key = "orphans" }, -- standalone, no argument
  ["!"] = { raw = true }, -- raw passthrough
}

--- Check whether a single term starts with a recognized query prefix.
---@param term string Trimmed term
---@return boolean
local function has_prefix(term)
  if term == "" then
    return false
  end
  local first = term:sub(1, 1)
  return PREFIX_MAP[first] ~= nil
end

--- Translate a single term to snot query syntax.
--- Bare words (no prefix) in query mode become `title:<word>`.
---@param term string Trimmed term
---@param query_mode boolean Whether the overall input contains any prefixed terms
---@return string|nil translated term, or nil if empty
local function translate_term(term, query_mode)
  if term == "" then
    return nil
  end

  local first = term:sub(1, 1)
  local mapping = PREFIX_MAP[first]

  if not mapping then
    -- Bare word in query mode → title search
    if query_mode then
      return "title:" .. term
    end
    return nil
  end

  -- Raw passthrough: strip `!`, pass rest verbatim
  if mapping.raw then
    local rest = term:sub(2)
    return rest ~= "" and rest or nil
  end

  -- Orphans: standalone keyword, no argument
  if mapping.key == "orphans" then
    return "orphans"
  end

  local arg = vim.trim(term:sub(2))
  if arg == "" then
    return nil
  end

  -- Fuzzy prefix `~` → pass as `~<arg>` (snot native syntax)
  if mapping.key == "~" then
    return "~" .. arg
  end

  return mapping.key .. ":" .. arg
end

--- Check whether the input contains any query prefixes.
--- Splits on `|` and `&`, trims each term, checks for prefix chars.
---@param input string Raw picker input
---@return boolean
function M.is_query(input)
  if not input or input == "" then
    return false
  end

  -- Split on | first, then & within each group
  for or_group in input:gmatch("[^|]+") do
    for and_term in or_group:gmatch("[^&]+") do
      local term = vim.trim(and_term)
      if has_prefix(term) then
        return true
      end
    end
  end

  return false
end

--- Parse picker input into a snot query string.
--- Returns nil if the input has no query prefixes (plain text mode).
---@param input string Raw picker input
---@return string|nil snot query string
function M.parse(input)
  if not input or input == "" then
    return nil
  end

  if not M.is_query(input) then
    return nil
  end

  local or_parts = {}

  for or_group in input:gmatch("[^|]+") do
    local and_parts = {}

    for and_term in or_group:gmatch("[^&]+") do
      local term = vim.trim(and_term)
      local translated = translate_term(term, true)
      if translated then
        table.insert(and_parts, translated)
      end
    end

    if #and_parts > 0 then
      -- AND terms joined with space (snot implicit AND)
      table.insert(or_parts, table.concat(and_parts, " "))
    end
  end

  if #or_parts == 0 then
    return nil
  end

  -- OR groups joined with " OR "
  return table.concat(or_parts, " OR ")
end

return M
