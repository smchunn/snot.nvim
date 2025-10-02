local M = {}
local backend = require("snot.backend")
local ui = require("snot.ui")
local picker = require("snot.picker")

function M.setup(config)
  -- NoteNew - Create a new note
  vim.api.nvim_create_user_command("NoteNew", function(opts)
    local name = opts.args
    if name == "" then
      vim.ui.input({ prompt = "Note name: " }, function(input)
        if input then
          M.create_note(input)
        end
      end)
    else
      M.create_note(name)
    end
  end, { nargs = "?", desc = "Create a new note" })

  -- NoteFind - Open file picker
  vim.api.nvim_create_user_command("NoteFind", function()
    M.find_note()
  end, { desc = "Find and open a note" })

  -- NoteSearch - Search using query language
  vim.api.nvim_create_user_command("NoteSearch", function(opts)
    local query = opts.args
    if query == "" then
      vim.ui.input({ prompt = "Query: " }, function(input)
        if input then
          M.search_notes(input)
        end
      end)
    else
      M.search_notes(query)
    end
  end, { nargs = "?", desc = "Search notes using query language" })

  -- NoteBacklinks - Show backlinks to current note
  vim.api.nvim_create_user_command("NoteBacklinks", function()
    M.show_backlinks()
  end, { desc = "Show backlinks to current note" })

  -- NoteIndex - Reindex all notes
  vim.api.nvim_create_user_command("NoteIndex", function(opts)
    local force = opts.bang
    M.index_vault(force)
  end, { bang = true, desc = "Index vault (use ! to force reindex)" })

  -- NoteInit - Initialize vault
  vim.api.nvim_create_user_command("NoteInit", function(opts)
    local vault_path = opts.args
    if vault_path == "" then
      vault_path = vim.fn.getcwd()
    end
    M.init_vault(vault_path)
  end, { nargs = "?", desc = "Initialize vault" })

  -- NoteLink - Insert link to another note
  vim.api.nvim_create_user_command("NoteLink", function()
    M.insert_link()
  end, { desc = "Insert link to another note" })
end

function M.create_note(name)
  backend.create_note(name, function(err, result)
    if err then
      vim.notify("Error creating note: " .. err, vim.log.levels.ERROR)
      return
    end

    -- Open the newly created note
    vim.cmd("edit " .. result.path)
    vim.notify("Created note: " .. result.title, vim.log.levels.INFO)
  end)
end

function M.find_note(query)
  backend.list_notes(query, function(err, output)
    if err then
      vim.notify("Error listing notes: " .. err, vim.log.levels.ERROR)
      return
    end

    -- Convert output to list of file paths
    local files = {}
    for _, line in ipairs(output) do
      if line ~= "" then
        table.insert(files, line)
      end
    end

    if #files == 0 then
      vim.notify("No notes found", vim.log.levels.WARN)
      return
    end

    -- Use picker (FZF, Telescope, or vim.ui.select)
    picker.pick(files, {
      prompt = "Find Note> ",
      preview_command = "cat {}",
    })
  end)
end

function M.search_notes(query)
  backend.query_notes(query, function(err, results)
    if err then
      vim.notify("Error searching notes: " .. err, vim.log.levels.ERROR)
      return
    end

    if #results == 0 then
      vim.notify("No notes found", vim.log.levels.WARN)
      return
    end

    ui.show_results(results, "Search Results: " .. query)
  end)
end

function M.show_backlinks()
  local file_path = vim.fn.expand("%:p")

  backend.get_backlinks(file_path, function(err, results)
    if err then
      vim.notify("Error getting backlinks: " .. err, vim.log.levels.ERROR)
      return
    end

    if #results == 0 then
      vim.notify("No backlinks found", vim.log.levels.INFO)
      return
    end

    ui.show_results(results, "Backlinks")
  end)
end

function M.index_vault(force)
  vim.notify("Indexing vault...", vim.log.levels.INFO)

  backend.index_vault(force, function(err, output)
    if err then
      vim.notify("Error indexing vault: " .. err, vim.log.levels.ERROR)
      return
    end

    local message = table.concat(output, "\n")
    vim.notify(message, vim.log.levels.INFO)
  end)
end

function M.init_vault(vault_path)
  backend.init_vault(vault_path, function(err, output)
    if err then
      vim.notify("Error initializing vault: " .. err, vim.log.levels.ERROR)
      return
    end

    local message = table.concat(output, "\n")
    vim.notify(message, vim.log.levels.INFO)
  end)
end

function M.insert_link()
  backend.list_notes(nil, function(err, output)
    if err then
      vim.notify("Error listing notes: " .. err, vim.log.levels.ERROR)
      return
    end

    -- Convert output to list of file paths
    local files = {}
    for _, line in ipairs(output) do
      if line ~= "" then
        table.insert(files, line)
      end
    end

    if #files == 0 then
      vim.notify("No notes found", vim.log.levels.WARN)
      return
    end

    -- Use picker to select a file for linking
    picker.pick(files, {
      prompt = "Insert Link> ",
      preview_command = "cat {}",
      on_select = function(selected)
        -- Extract note name from path and create wiki link
        local note_name = vim.fn.fnamemodify(selected, ":t:r")
        local link = "[[" .. note_name .. "]]"

        -- Insert at cursor
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local line = vim.api.nvim_get_current_line()
        local new_line = line:sub(1, col) .. link .. line:sub(col + 1)
        vim.api.nvim_set_current_line(new_line)

        -- Move cursor to after the link
        vim.api.nvim_win_set_cursor(0, { row, col + #link })
      end,
    })
  end)
end

return M
