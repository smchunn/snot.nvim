local M = {}

local config = {
  vault_path = vim.fn.getcwd(),
  snot_bin = "snot",
  picker = "auto", -- "auto", "fzf-lua", "telescope", or "select"
}

local function expand_path(path)
  if not path then
    return path
  end
  -- Expand ~ to home directory
  local expanded = vim.fn.expand(path)
  -- Convert to absolute path
  return vim.fn.fnamemodify(expanded, ":p")
end

function M.setup(opts)
  opts = opts or {}

  -- Expand paths before merging
  if opts.vault_path then
    opts.vault_path = expand_path(opts.vault_path)
  end

  config = vim.tbl_deep_extend("force", config, opts)

  -- Create user commands
  require("snot.commands").setup(config)

  -- Set up auto-completion
  if opts.enable_completion ~= false then
    require("snot.completion").setup()

    -- Try to set up nvim-cmp integration if available
    pcall(function()
      require("snot.completion").setup_cmp()
    end)

    -- Try to set up blink.cmp integration if available
    pcall(function()
      require("snot.completion").setup_blink()
    end)
  end

  -- Set up autocmd to update cache on save
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.md",
    callback = function(args)
      local file_path = args.file
      -- Only update if file is in vault
      if config.vault_path and vim.startswith(file_path, config.vault_path) then
        local backend = require("snot.backend")
        backend.update_note(file_path, function(err, _)
          if err then
            vim.notify("Failed to update note cache: " .. err, vim.log.levels.WARN)
          end
        end)
      end
    end,
  })
end

function M.get_config()
  return config
end

return M
