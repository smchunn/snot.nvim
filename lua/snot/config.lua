local M = {}

---@class SnotConfig
---@field vault_path string
---@field snot_bin string
---@field picker "auto"|"fzf-lua"|"snacks"|"telescope"|"select"
---@field templates { dir: string, default: string }

M.defaults = {
  vault_path = nil,
  snot_bin = "snot",
  picker = "auto",
  templates = {
    dir = "templates",
    default = "default.md",
  },
}

local valid_pickers = { auto = true, ["fzf-lua"] = true, snacks = true, telescope = true, select = true }

--- Deep merge user opts into defaults, validate, and return config.
---@param user_opts table|nil
---@return SnotConfig
function M.validate(user_opts)
  user_opts = user_opts or {}
  local config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_opts)

  -- vault_path is required
  if not config.vault_path or config.vault_path == "" then
    vim.notify("[snot] vault_path is required in setup()", vim.log.levels.ERROR)
    error("snot: vault_path is required")
  end

  -- Expand ~ and resolve to absolute path
  config.vault_path = vim.fn.fnamemodify(vim.fn.expand(config.vault_path), ":p")
  -- Strip trailing slash
  config.vault_path = config.vault_path:gsub("/$", "")

  -- Validate picker
  if not valid_pickers[config.picker] then
    vim.notify(
      string.format("[snot] Invalid picker '%s', falling back to 'auto'", config.picker),
      vim.log.levels.WARN
    )
    config.picker = "auto"
  end

  return config
end

return M
