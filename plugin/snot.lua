if vim.g.loaded_snot then
  return
end
vim.g.loaded_snot = true

local function dispatch(name, opts)
  require("snot.commands").dispatch(name, opts)
end

vim.api.nvim_create_user_command("SnotNew", function(opts)
  dispatch("new", opts)
end, { nargs = "?", bang = true, desc = "Create a new note" })

vim.api.nvim_create_user_command("SnotFind", function(opts)
  dispatch("find", opts)
end, { nargs = "?", desc = "Browse notes or search with query syntax" })

vim.api.nvim_create_user_command("SnotBacklinks", function(opts)
  dispatch("backlinks", opts)
end, { nargs = 0, desc = "Show backlinks to current note" })

vim.api.nvim_create_user_command("SnotIndex", function(opts)
  dispatch("index", opts)
end, { nargs = 0, bang = true, desc = "Index vault" })

vim.api.nvim_create_user_command("SnotTags", function(opts)
  dispatch("tags", opts)
end, { nargs = 0, desc = "Browse all tags" })

vim.api.nvim_create_user_command("SnotGraph", function(opts)
  dispatch("graph", opts)
end, { nargs = "?", desc = "Graph operations (neighbors, orphans, stats)" })

vim.api.nvim_create_user_command("SnotLink", function(opts)
  dispatch("link", opts)
end, { nargs = 0, desc = "Insert wiki-link to a note" })
