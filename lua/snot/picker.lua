local M = {}

--- Detect which picker backend is available.
---@return "fzf-lua"|"snacks"|"telescope"|"select"
local function detect_picker()
  local ok
  ok, _ = pcall(require, "fzf-lua")
  if ok then
    return "fzf-lua"
  end
  ok, _ = pcall(require, "snacks")
  if ok then
    return "snacks"
  end
  ok, _ = pcall(require, "telescope")
  if ok then
    return "telescope"
  end
  return "select"
end

--- Resolve the picker backend from config.
---@return "fzf-lua"|"snacks"|"telescope"|"select"
local function resolve_picker()
  local config = require("snot").get_config()
  if config.picker == "auto" then
    return detect_picker()
  end
  return config.picker
end

--- Pick from a list of items using the configured picker.
---@param items { text: string, path: string?, data: any? }[]
---@param opts { prompt?: string, on_select?: fun(item: table) }
function M.pick(items, opts)
  opts = opts or {}
  local prompt = opts.prompt or "Snot"

  local on_select = opts.on_select or function(item)
    if item.path then
      vim.cmd("edit " .. vim.fn.fnameescape(item.path))
    end
  end

  if #items == 0 then
    vim.notify("[snot] No results", vim.log.levels.INFO)
    return
  end

  local backend = resolve_picker()

  if backend == "fzf-lua" then
    M._pick_fzf_lua(items, prompt, on_select)
  elseif backend == "snacks" then
    M._pick_snacks(items, prompt, on_select)
  elseif backend == "telescope" then
    M._pick_telescope(items, prompt, on_select)
  else
    M._pick_select(items, prompt, on_select)
  end
end

---@private
function M._pick_fzf_lua(items, prompt, on_select)
  local fzf = require("fzf-lua")

  -- Build display strings and a lookup table
  local display_strings = {}
  local lookup = {}
  for _, item in ipairs(items) do
    table.insert(display_strings, item.text)
    lookup[item.text] = item
  end

  fzf.fzf_exec(display_strings, {
    prompt = prompt .. "> ",
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          local item = lookup[selected[1]]
          if item then
            on_select(item)
          end
        end
      end,
    },
  })
end

---@private
function M._pick_snacks(items, prompt, on_select)
  local Snacks = require("snacks")

  local picker_items = {}
  for idx, item in ipairs(items) do
    table.insert(picker_items, {
      idx = idx,
      text = item.text,
      file = item.path,
      item = item,
    })
  end

  Snacks.picker.pick({
    source = "snot",
    title = prompt,
    items = picker_items,
    confirm = function(picker, picker_item)
      picker:close()
      if picker_item and picker_item.item then
        on_select(picker_item.item)
      end
    end,
  })
end

---@private
function M._pick_telescope(items, prompt, on_select)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = prompt,
      finder = finders.new_table({
        results = items,
        entry_maker = function(item)
          return {
            value = item,
            display = item.text,
            ordinal = item.text,
            path = item.path,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            on_select(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

---@private
function M._pick_select(items, prompt, on_select)
  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if choice then
      on_select(choice)
    end
  end)
end

return M
