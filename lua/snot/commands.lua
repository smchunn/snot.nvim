local M = {}

local backend, picker, templates, utils

--- Lazy-load dependencies on first dispatch.
local function ensure_deps()
  if not backend then
    backend = require("snot.backend")
    picker = require("snot.picker")
    templates = require("snot.templates")
    utils = require("snot.utils")
  end
end

--- Notify an error from a backend call.
---@param context string What we were trying to do
---@param err string The error message
local function notify_err(context, err)
  vim.notify(string.format("[snot] %s: %s", context, err), vim.log.levels.ERROR)
end

--- Build picker items from note objects (with id, title, path).
--- Note: the `path` field from the CLI is already an absolute path.
---@param notes table[] Array of {id, title, path} objects
---@return table[] items for picker
local function notes_to_items(notes)
  local items = {}
  for _, note in ipairs(notes) do
    table.insert(items, {
      text = note.title .. "  (" .. note.id .. ")",
      path = note.path,
      data = note,
    })
  end
  return items
end

-- Command handlers -------------------------------------------------------

local function cmd_new(opts)
  local title = opts.args ~= "" and opts.args or nil
  local use_picker = opts.bang

  local function create_with_template(name, template_path)
    local content, vars = templates.render(name, template_path)
    local config = require("snot").get_config()
    local file_path = config.vault_path .. "/" .. vars.id .. ".md"

    if vim.fn.filereadable(file_path) == 1 then
      vim.notify("[snot] Note already exists: " .. file_path, vim.log.levels.WARN)
      return
    end

    -- Ensure parent directory exists
    vim.fn.mkdir(vim.fn.fnamemodify(file_path, ":h"), "p")

    -- Write file
    local lines = vim.split(content, "\n")
    vim.fn.writefile(lines, file_path)

    -- Open the file
    vim.cmd("edit " .. vim.fn.fnameescape(file_path))

    -- Register in database
    backend.update_note(file_path, function(err)
      if err then
        notify_err("Update after create", err)
      end
    end)
  end

  local function proceed_with_title(name)
    if use_picker then
      -- Pick a template first
      local tpls = templates.list_templates()
      if #tpls == 0 then
        vim.notify("[snot] No templates found, using default", vim.log.levels.INFO)
        create_with_template(name, nil)
        return
      end

      local items = {}
      for _, t in ipairs(tpls) do
        table.insert(items, { text = t.name, path = t.path, data = t })
      end

      picker.pick(items, {
        prompt = "Template",
        on_select = function(item)
          create_with_template(name, item.path)
        end,
      })
    else
      create_with_template(name, nil)
    end
  end

  if title then
    proceed_with_title(title)
  else
    vim.ui.input({ prompt = "Note title: " }, function(input)
      if not input or input == "" then
        return
      end
      proceed_with_title(input)
    end)
  end
end

local function cmd_find(opts)
  local config = require("snot").get_config()
  local snot_bin = config.snot_bin
  local vault_path = config.vault_path
  local query_parser = require("snot.query")

  --- List all notes for local fuzzy filtering.
  ---@return table[] items
  local function list_all_notes()
    local raw = vim.fn.system({ snot_bin, "list", vault_path })
    if vim.v.shell_error ~= 0 then
      return {}
    end
    local items = {}
    for line in raw:gmatch("[^\n]+") do
      if line ~= "" then
        local stem = utils.note_stem(line)
        table.insert(items, {
          text = stem .. "  (" .. line .. ")",
          path = line,
        })
      end
    end
    return items
  end

  --- Run a snot query and return picker items.
  ---@param snot_query string Translated snot query string
  ---@return table[] items
  local function run_query(snot_query)
    local raw = vim.fn.system({ snot_bin, "query", vault_path, snot_query })
    if vim.v.shell_error ~= 0 then
      return {}
    end
    local ok, notes = pcall(vim.json.decode, raw)
    if not ok or type(notes) ~= "table" then
      return {}
    end
    return notes_to_items(notes)
  end

  picker.pick_live({
    prompt = "Notes",
    initial_query = opts.args ~= "" and opts.args or nil,
    search = function(input)
      local snot_query = query_parser.parse(input)
      if snot_query then
        return run_query(snot_query)
      end
      -- Plain text (no prefixes) → list all notes, picker fuzzy-filters locally
      return list_all_notes()
    end,
  })
end

local function cmd_backlinks()
  local file = utils.current_file()
  if not file then
    vim.notify("[snot] No file in current buffer", vim.log.levels.WARN)
    return
  end

  backend.get_backlinks(file, function(err, notes)
    if err then
      notify_err("Backlinks", err)
      return
    end
    picker.pick(notes_to_items(notes), { prompt = "Backlinks" })
  end)
end

local function cmd_index(opts)
  local force = opts.bang
  backend.index_vault(force, function(err, output)
    if err then
      notify_err("Index", err)
      return
    end
    vim.notify("[snot] " .. output, vim.log.levels.INFO)
  end)
end

local function cmd_tags()
  backend.list_tags(function(err, tags)
    if err then
      notify_err("Tags", err)
      return
    end

    local items = {}
    for _, tag in ipairs(tags) do
      table.insert(items, { text = tag })
    end

    picker.pick(items, {
      prompt = "Tags",
      on_select = function(item)
        -- Re-search with the selected tag
        backend.query_notes("tag:" .. item.text, function(search_err, notes)
          if search_err then
            notify_err("Tag search", search_err)
            return
          end
          picker.pick(notes_to_items(notes), { prompt = "tag:" .. item.text })
        end)
      end,
    })
  end)
end

local function cmd_graph(opts)
  local subcmd = opts.args ~= "" and opts.args or "neighbors"

  if subcmd == "stats" then
    backend.graph_stats(function(err, stats)
      if err then
        notify_err("Graph stats", err)
        return
      end

      local lines = {
        "Graph Statistics:",
        "  Total notes:  " .. (stats.total_notes or 0),
        "  Linked:       " .. (stats.linked_count or 0),
        "  Orphans:      " .. (stats.orphan_count or 0),
      }
      if stats.most_linked and #stats.most_linked > 0 then
        table.insert(lines, "  Most linked:")
        for _, entry in ipairs(stats.most_linked) do
          table.insert(lines, "    " .. entry.title .. " (" .. entry.link_count .. " links)")
        end
      end
      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
    end)
    return
  end

  if subcmd == "orphans" then
    backend.graph_orphans(function(err, notes)
      if err then
        notify_err("Graph orphans", err)
        return
      end
      picker.pick(notes_to_items(notes), { prompt = "Orphans" })
    end)
    return
  end

  -- Default: neighbors of current note
  local file = utils.current_file()
  if not file then
    vim.notify("[snot] No file in current buffer", vim.log.levels.WARN)
    return
  end

  local config = require("snot").get_config()
  local note_id, id_err = utils.note_id_from_path(file, config.vault_path)
  if not note_id then
    vim.notify("[snot] " .. (id_err or "Could not determine note ID"), vim.log.levels.WARN)
    return
  end

  backend.graph_neighbors(note_id, 2, function(err, notes)
    if err then
      notify_err("Graph neighbors", err)
      return
    end
    picker.pick(notes_to_items(notes), { prompt = "Neighbors: " .. note_id })
  end)
end

local function cmd_link()
  backend.list_notes(function(err, paths)
    if err then
      notify_err("List notes", err)
      return
    end

    local items = {}
    for _, path in ipairs(paths) do
      local stem = utils.note_stem(path)
      table.insert(items, {
        text = stem .. "  (" .. path .. ")",
        path = path,
        data = { stem = stem },
      })
    end

    picker.pick(items, {
      prompt = "Insert Link",
      on_select = function(item)
        local link = "[[" .. item.data.stem .. "]]"
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local line = vim.api.nvim_get_current_line()
        local before = line:sub(1, col)
        local after = line:sub(col + 1)
        vim.api.nvim_set_current_line(before .. link .. after)
        vim.api.nvim_win_set_cursor(0, { row, col + #link })
      end,
    })
  end)
end

-- Dispatch ---------------------------------------------------------------

local handlers = {
  new = cmd_new,
  find = cmd_find,
  backlinks = cmd_backlinks,
  index = cmd_index,
  tags = cmd_tags,
  graph = cmd_graph,
  link = cmd_link,
}

--- Dispatch a command by name.
---@param name string Command name
---@param opts table Command opts from nvim_create_user_command
function M.dispatch(name, opts)
  ensure_deps()
  local handler = handlers[name]
  if not handler then
    vim.notify("[snot] Unknown command: " .. name, vim.log.levels.ERROR)
    return
  end
  handler(opts)
end

return M
