local M = {}

--- Run a snot CLI command asynchronously.
--- Collects stdout/stderr, calls callback(err, data) on exit.
---@param args string[] CLI arguments (after the binary name)
---@param opts { parse_json?: boolean } Options
---@param callback fun(err: string|nil, data: any) Called on completion
function M.run_command(args, opts, callback)
  local config = require("snot").get_config()
  local cmd = vim.list_extend({ config.snot_bin }, args)

  local stdout_chunks = {}
  local stderr_chunks = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout_chunks, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr_chunks, data)
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        local stdout = table.concat(stdout_chunks, "\n"):gsub("\n+$", "")
        local stderr = table.concat(stderr_chunks, "\n"):gsub("\n+$", "")

        if exit_code ~= 0 then
          local msg = stderr ~= "" and stderr or ("snot exited with code " .. exit_code)
          callback(msg, nil)
          return
        end

        if opts.parse_json and stdout ~= "" then
          local ok, decoded = pcall(vim.json.decode, stdout)
          if not ok then
            callback("Failed to parse JSON: " .. tostring(decoded), nil)
            return
          end
          callback(nil, decoded)
        else
          callback(nil, stdout)
        end
      end)
    end,
  })
end

--- Index the vault.
---@param force boolean Whether to force full reindex
---@param callback fun(err: string|nil, data: string|nil)
function M.index_vault(force, callback)
  local config = require("snot").get_config()
  local args = { "index", config.vault_path }
  if force then
    table.insert(args, "--force")
  end
  M.run_command(args, {}, callback)
end

--- Create a note via CLI.
---@param name string Note title
---@param callback fun(err: string|nil, data: table|nil)
function M.create_note(name, callback)
  local config = require("snot").get_config()
  M.run_command({ "create", config.vault_path, name }, { parse_json = true }, callback)
end

--- Query notes.
---@param query string Query string (shorthand or SQL)
---@param callback fun(err: string|nil, data: table[]|nil)
function M.query_notes(query, callback)
  local config = require("snot").get_config()
  M.run_command({ "query", config.vault_path, query }, { parse_json = true }, callback)
end

--- Get backlinks to a file.
---@param file_path string Absolute path to the note
---@param callback fun(err: string|nil, data: table[]|nil)
function M.get_backlinks(file_path, callback)
  local config = require("snot").get_config()
  M.run_command({ "backlinks", config.vault_path, file_path }, { parse_json = true }, callback)
end

--- List all notes (one path per line).
---@param callback fun(err: string|nil, data: string[]|nil)
function M.list_notes(callback)
  local config = require("snot").get_config()
  M.run_command({ "list", config.vault_path }, {}, function(err, stdout)
    if err then
      callback(err, nil)
      return
    end
    local lines = {}
    for line in stdout:gmatch("[^\n]+") do
      if line ~= "" then
        table.insert(lines, line)
      end
    end
    callback(nil, lines)
  end)
end

--- List all tags.
---@param callback fun(err: string|nil, data: string[]|nil)
function M.list_tags(callback)
  local config = require("snot").get_config()
  M.run_command({ "tags", config.vault_path }, { parse_json = true }, callback)
end

--- Get graph neighbors for a note.
---@param id string Note ID
---@param depth number Traversal depth
---@param callback fun(err: string|nil, data: table[]|nil)
function M.graph_neighbors(id, depth, callback)
  local config = require("snot").get_config()
  M.run_command(
    { "graph", "neighbors", config.vault_path, id, "--depth", tostring(depth) },
    { parse_json = true },
    callback
  )
end

--- Get orphaned notes.
---@param callback fun(err: string|nil, data: table[]|nil)
function M.graph_orphans(callback)
  local config = require("snot").get_config()
  M.run_command({ "graph", "orphans", config.vault_path }, { parse_json = true }, callback)
end

--- Get graph statistics.
---@param callback fun(err: string|nil, data: table|nil)
function M.graph_stats(callback)
  local config = require("snot").get_config()
  M.run_command({ "graph", "stats", config.vault_path }, { parse_json = true }, callback)
end

--- Update a single note in the database.
---@param file_path string Absolute path to the note
---@param callback fun(err: string|nil, data: string|nil)
function M.update_note(file_path, callback)
  local config = require("snot").get_config()
  M.run_command({ "update", config.vault_path, file_path }, {}, callback)
end

return M
