local M = {}

local FALLBACK_TEMPLATE = [[---
id: {{id}}
aliases:
  - {{title}}
tags: []
---

# {{title}}

]]

--- Get the templates directory path.
---@return string
function M.templates_dir()
  local config = require("snot").get_config()
  return config.vault_path .. "/" .. config.templates.dir
end

--- List available templates in the templates directory.
---@return { name: string, path: string }[]
function M.list_templates()
  local dir = M.templates_dir()
  local templates = {}
  local glob = vim.fn.glob(dir .. "/*.md", false, true)
  for _, path in ipairs(glob) do
    local name = vim.fn.fnamemodify(path, ":t")
    table.insert(templates, { name = name, path = path })
  end
  return templates
end

--- Read template content from a file path.
---@param path string
---@return string|nil
function M.read_template(path)
  local lines = vim.fn.readfile(path)
  if #lines == 0 then
    return nil
  end
  return table.concat(lines, "\n") .. "\n"
end

--- Get the default template content.
--- Reads from the configured default template file, or returns the hardcoded fallback.
---@return string
function M.get_default_template()
  local config = require("snot").get_config()
  local default_path = M.templates_dir() .. "/" .. config.templates.default
  if vim.fn.filereadable(default_path) == 1 then
    local content = M.read_template(default_path)
    if content then
      return content
    end
  end
  return FALLBACK_TEMPLATE
end

--- Build template variables from a note title.
---@param title string
---@return table<string, string>
function M.build_vars(title)
  local utils = require("snot.utils")
  local date = os.date("%Y-%m-%d")
  local time = os.date("%H:%M:%S")
  local id = utils.normalize_note_id(title) .. "-" .. date
  return {
    title = title,
    date = date,
    time = time,
    datetime = date .. "T" .. time,
    id = id,
  }
end

--- Expand {{key}} patterns in a template string.
---@param template string
---@param vars table<string, string>
---@return string
function M.expand(template, vars)
  return (template:gsub("{{(%w+)}}", function(key)
    return vars[key] or ("{{" .. key .. "}}")
  end))
end

--- Full render pipeline: build vars, load template, expand, return content + vars.
---@param title string Note title
---@param template_path? string Optional path to a template file
---@return string content, table vars
function M.render(title, template_path)
  local vars = M.build_vars(title)
  local template
  if template_path then
    template = M.read_template(template_path) or M.get_default_template()
  else
    template = M.get_default_template()
  end
  local content = M.expand(template, vars)
  return content, vars
end

return M
