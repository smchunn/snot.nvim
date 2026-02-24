local M = {}

---@type SnotConfig|nil
local _config = nil

--- Set up the plugin. Must be called before any commands.
---@param opts table User configuration
function M.setup(opts)
  local config_mod = require("snot.config")
  _config = config_mod.validate(opts)

  -- Auto-update note on save for markdown files inside the vault
  local group = vim.api.nvim_create_augroup("SnotAutoUpdate", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.md",
    callback = function(ev)
      local file = vim.fn.fnamemodify(ev.file, ":p")
      local vault = _config.vault_path .. "/"
      if vim.startswith(file, vault) then
        require("snot.backend").update_note(file, function(err)
          if err then
            vim.notify("[snot] Update failed: " .. err, vim.log.levels.WARN)
          end
        end)
      end
    end,
  })
end

--- Get the current config. Errors if setup() hasn't been called.
---@return SnotConfig
function M.get_config()
  if not _config then
    error("snot: setup() must be called before using any commands")
  end
  return _config
end

return M
