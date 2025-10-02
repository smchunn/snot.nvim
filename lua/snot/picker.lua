local M = {}

-- Check if fzf-lua is available
local function has_fzf_lua()
  return pcall(require, "fzf-lua")
end

-- Check if telescope is available
local function has_telescope()
  return pcall(require, "telescope")
end

-- FZF-Lua picker
local function pick_with_fzf_lua(files, opts)
  opts = opts or {}
  local fzf_lua = require("fzf-lua")

  fzf_lua.fzf_exec(files, {
    prompt = opts.prompt or "Notes> ",
    previewer = "builtin",
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          if opts.on_select then
            opts.on_select(selected[1])
          else
            vim.cmd("edit " .. selected[1])
          end
        end
      end,
    },
    fzf_opts = {
      ["--preview-window"] = "right:60%:wrap",
    },
  })
end

-- Telescope picker
local function pick_with_telescope(files, opts)
  opts = opts or {}
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new(opts, {
    prompt_title = opts.prompt or "Notes",
    finder = finders.new_table({
      results = files,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if opts.on_select then
          opts.on_select(selection[1])
        else
          vim.cmd("edit " .. selection[1])
        end
      end)
      return true
    end,
  }):find()
end

-- Fallback to vim.ui.select
local function pick_with_select(files, opts)
  opts = opts or {}

  -- Format files for display
  local items = {}
  for _, file in ipairs(files) do
    local display = vim.fn.fnamemodify(file, ":t:r")
    table.insert(items, { display = display, path = file })
  end

  vim.ui.select(items, {
    prompt = opts.prompt or "Select note:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if choice then
      if opts.on_select then
        opts.on_select(choice.path)
      else
        vim.cmd("edit " .. choice.path)
      end
    end
  end)
end

-- Main picker function that chooses the best available picker
function M.pick(files, opts)
  opts = opts or {}

  if #files == 0 then
    vim.notify("No files to pick from", vim.log.levels.WARN)
    return
  end

  -- Use configured picker if specified
  local config = require("snot").get_config()
  local picker_type = config.picker or "auto"

  if picker_type == "fzf-lua" or picker_type == "fzf" or (picker_type == "auto" and has_fzf_lua()) then
    pick_with_fzf_lua(files, opts)
  elseif picker_type == "telescope" or (picker_type == "auto" and has_telescope()) then
    pick_with_telescope(files, opts)
  else
    pick_with_select(files, opts)
  end
end

return M
