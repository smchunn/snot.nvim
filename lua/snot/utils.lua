local M = {}

--- Extract filename without extension from a path.
---@param filepath string
---@return string
function M.note_stem(filepath)
  return vim.fn.fnamemodify(filepath, ":t:r")
end

--- Get absolute path of the current buffer, or nil if unnamed.
---@return string|nil
function M.current_file()
  local buf = vim.api.nvim_buf_get_name(0)
  if buf == "" then
    return nil
  end
  return vim.fn.fnamemodify(buf, ":p")
end

--- Mirror Rust's normalize_note_id: lowercase, spaces to hyphens,
--- strip non-alphanumeric except - and _.
---@param name string
---@return string
function M.normalize_note_id(name)
  local trimmed = vim.trim(name)
  local lower = trimmed:lower()
  local with_hyphens = lower:gsub(" ", "-")
  local cleaned = with_hyphens:gsub("[^%w%-_]", "")
  return cleaned
end

--- Generate note ID from a file path relative to the vault.
--- Mirrors Rust's note_id_from_path.
---@param filepath string Absolute path to the file
---@param vault_path string Absolute path to the vault root
---@return string|nil id, string|nil error
function M.note_id_from_path(filepath, vault_path)
  -- Ensure vault_path ends with / for stripping
  local prefix = vault_path:gsub("/$", "") .. "/"
  if not vim.startswith(filepath, prefix) then
    return nil, "File is not inside vault"
  end
  local relative = filepath:sub(#prefix + 1)
  -- Strip .md extension
  relative = relative:gsub("%.md$", "")
  -- Replace path separators with hyphens
  relative = relative:gsub("[/\\]", "-")
  return M.normalize_note_id(relative), nil
end

return M
