local M = {}

function M.show_results(results, title)
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "snot-results")

  -- Build the content
  local lines = { title, string.rep("=", #title), "" }

  for i, note in ipairs(results) do
    table.insert(lines, string.format("%d. %s", i, note.title))
    table.insert(lines, string.format("   Path: %s", note.path))

    if note.tags and #note.tags > 0 then
      local tags_str = table.concat(vim.tbl_values(note.tags), ", ")
      table.insert(lines, string.format("   Tags: %s", tags_str))
    end

    table.insert(lines, "")
  end

  -- Set the content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Open in a split
  vim.cmd("split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Set up keymaps for the results buffer
  local opts = { noremap = true, silent = true, buffer = buf }

  -- Press Enter to open the note
  vim.keymap.set("n", "<CR>", function()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]

    -- Find which result this corresponds to
    local result_idx = nil
    local current_line = 0

    for i = 1, #results do
      current_line = current_line + 1 -- Title line
      if current_line == line_num then
        result_idx = i
        break
      end

      current_line = current_line + 1 -- Path line

      if results[i].tags and #results[i].tags > 0 then
        current_line = current_line + 1 -- Tags line
      end

      current_line = current_line + 1 -- Empty line
    end

    -- Adjust for header lines
    if line_num > 3 then
      for i = 1, #results do
        local start_line = 4 + (i - 1) * 3
        if results[i].tags and #results[i].tags > 0 then
          start_line = 4 + (i - 1) * 4
        end

        if line_num >= start_line and line_num < start_line + 3 then
          result_idx = i
          break
        end
      end
    end

    if result_idx then
      vim.cmd("close")
      vim.cmd("edit " .. results[result_idx].path)
    end
  end, opts)

  -- Press q to close
  vim.keymap.set("n", "q", function()
    vim.cmd("close")
  end, opts)
end

return M
