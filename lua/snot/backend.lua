local M = {}

local function get_vault_path()
  local config = require("snot").get_config()
  return config.vault_path
end

local function get_snot_bin()
  local config = require("snot").get_config()
  return config.snot_bin
end

function M.run_command(args, callback)
  local cmd = get_snot_bin()
  local full_args = vim.list_extend({}, args)

  local stdout = {}
  local stderr = {}

  local job_id = vim.fn.jobstart({ cmd, unpack(full_args) }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr, data)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        callback(nil, stdout)
      else
        callback(table.concat(stderr, "\n"), nil)
      end
    end,
  })

  return job_id
end

function M.init_vault(vault_path, callback)
  M.run_command({ "init", vault_path }, callback)
end

function M.index_vault(force, callback)
  local args = { "index", get_vault_path() }
  if force then
    table.insert(args, "--force")
  end
  M.run_command(args, callback)
end

function M.create_note(name, callback)
  M.run_command({ "create", get_vault_path(), name }, function(err, output)
    if err then
      callback(err, nil)
      return
    end

    local json_str = table.concat(output, "")
    local ok, result = pcall(vim.fn.json_decode, json_str)

    if ok then
      callback(nil, result)
    else
      callback("Failed to parse JSON response", nil)
    end
  end)
end

function M.query_notes(query, callback)
  M.run_command({ "query", get_vault_path(), query }, function(err, output)
    if err then
      callback(err, nil)
      return
    end

    local json_str = table.concat(output, "")
    local ok, result = pcall(vim.fn.json_decode, json_str)

    if ok then
      callback(nil, result)
    else
      callback("Failed to parse JSON response", nil)
    end
  end)
end

function M.get_backlinks(file_path, callback)
  M.run_command({ "backlinks", get_vault_path(), file_path }, function(err, output)
    if err then
      callback(err, nil)
      return
    end

    local json_str = table.concat(output, "")
    local ok, result = pcall(vim.fn.json_decode, json_str)

    if ok then
      callback(nil, result)
    else
      callback("Failed to parse JSON response", nil)
    end
  end)
end

function M.list_notes(query, callback)
  local args = { "list", get_vault_path() }
  if query then
    table.insert(args, "--query")
    table.insert(args, query)
  end

  M.run_command(args, callback)
end

function M.update_note(file_path, callback)
  M.run_command({ "update", get_vault_path(), file_path }, callback)
end

return M
