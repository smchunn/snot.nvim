local M = {}
local backend = require("snot.backend")

-- Cache for notes and tags
local cache = {
  notes = {},
  tags = {},
  last_update = 0,
}

local function update_cache()
  -- Only update cache every 5 seconds
  local now = vim.loop.now()
  if now - cache.last_update < 5000 then
    return
  end

  backend.list_notes(nil, function(err, output)
    if not err and output then
      cache.notes = {}
      for _, line in ipairs(output) do
        if line ~= "" then
          local note_name = vim.fn.fnamemodify(line, ":t:r")
          table.insert(cache.notes, note_name)
        end
      end
      cache.last_update = now
    end
  end)

  -- TODO: Get tags from database
  -- For now, we'll extract tags from the current buffer
  cache.tags = {}
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for _, line in ipairs(lines) do
    for tag in line:gmatch("#([%w_-]+)") do
      if not vim.tbl_contains(cache.tags, tag) then
        table.insert(cache.tags, tag)
      end
    end
  end
end

function M.setup()
  -- Set up autocompletion using omnifunc
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
      vim.bo.omnifunc = "v:lua.require'snot.completion'.omnifunc"
    end,
  })

  -- Update cache periodically
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    pattern = "*.md",
    callback = function()
      update_cache()
    end,
  })
end

function M.omnifunc(findstart, base)
  if findstart == 1 then
    -- Find the start of the completion
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    -- Check if we're in a wiki link [[
    local link_start = line:sub(1, col):find("%[%[[^%]]*$")
    if link_start then
      return link_start + 1 -- +1 to skip the [[
    end

    -- Check if we're typing a tag #
    local tag_start = line:sub(1, col):find("#[%w_-]*$")
    if tag_start then
      return tag_start -- Include the #
    end

    return -1
  else
    -- Return completions
    update_cache()

    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    -- Check if we're completing a link
    if line:sub(1, col):match("%[%[[^%]]*$") then
      local matches = {}
      for _, note in ipairs(cache.notes) do
        if note:find(base, 1, true) then
          table.insert(matches, {
            word = note,
            menu = "[Note]",
          })
        end
      end
      return matches
    end

    -- Check if we're completing a tag
    if line:sub(1, col):match("#[%w_-]*$") then
      local matches = {}
      for _, tag in ipairs(cache.tags) do
        if tag:find(base:sub(2), 1, true) then -- Skip the #
          table.insert(matches, {
            word = "#" .. tag,
            menu = "[Tag]",
          })
        end
      end
      return matches
    end

    return {}
  end
end

-- Smarter link completion using nvim-cmp if available
function M.setup_cmp()
  local has_cmp, cmp = pcall(require, "cmp")
  if not has_cmp then
    return
  end

  local source = {}

  function source:is_available()
    return vim.bo.filetype == "markdown"
  end

  function source:get_trigger_characters()
    return { "[", "#" }
  end

  function source:complete(params, callback)
    update_cache()

    local line = params.context.cursor_before_line
    local items = {}

    -- Wiki link completion
    if line:match("%[%[[^%]]*$") then
      for _, note in ipairs(cache.notes) do
        table.insert(items, {
          label = note,
          kind = cmp.lsp.CompletionItemKind.File,
          insertText = note .. "]]",
        })
      end
    end

    -- Tag completion
    if line:match("#[%w_-]*$") then
      for _, tag in ipairs(cache.tags) do
        table.insert(items, {
          label = "#" .. tag,
          kind = cmp.lsp.CompletionItemKind.Keyword,
        })
      end
    end

    callback({ items = items, isIncomplete = false })
  end

  cmp.register_source("snot", source)
end

-- blink.cmp source implementation
-- This is called directly by blink.cmp when configured
M.blink = {}

function M.blink.new(opts)
  local self = setmetatable({}, { __index = M.blink })
  self.opts = opts or {}
  return self
end

function M.blink:enabled()
  return vim.bo.filetype == "markdown"
end

function M.blink:get_trigger_characters()
  return { "[", "#" }
end

function M.blink:get_completions(ctx, callback)
  update_cache()

  local line = ctx.line
  local items = {}

  -- Wiki link completion
  if line:match("%[%[[^%]]*$") then
    for _, note in ipairs(cache.notes) do
      table.insert(items, {
        label = note,
        kind = 1, -- File kind (LSP CompletionItemKind)
        insertText = note .. "]]",
        sortText = note,
        filterText = note,
      })
    end
  end

  -- Tag completion
  if line:match("#[%w_-]*$") then
    for _, tag in ipairs(cache.tags) do
      table.insert(items, {
        label = "#" .. tag,
        kind = 14, -- Keyword kind (LSP CompletionItemKind)
        insertText = "#" .. tag,
        sortText = tag,
        filterText = tag,
      })
    end
  end

  callback({ items = items, isIncomplete = false })
end

-- Helper function to setup blink.cmp (optional, for auto-registration)
function M.setup_blink()
  -- blink.cmp will load the source via module path
  -- No explicit registration needed
end

return M
