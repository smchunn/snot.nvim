# snot.nvim

Neovim plugin for [SNOT](https://github.com/yourusername/snot) - Simple Note Organization Tool.

## Features

- **Note Management**: Create, find, and search notes with fuzzy finding
- **Wiki Links**: Auto-completion for `[[wiki-links]]`
- **Tag Completion**: Auto-completion for `#tags`
- **Backlinks**: View notes linking to the current note
- **Multiple Pickers**: Support for fzf-lua, telescope, or vim.ui.select
- **Auto-sync**: Automatically updates cache on save

## Requirements

- Neovim 0.7+
- [SNOT CLI](https://github.com/yourusername/snot) installed and in PATH
- Optional: [fzf-lua](https://github.com/ibhagwan/fzf-lua) or [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'yourusername/snot.nvim',
  opts = {
    vault_path = '~/notes',       -- Path to your notes vault
    snot_bin = 'snot',             -- Path to snot binary
    picker = 'auto',               -- 'auto', 'fzf-lua', 'telescope', or 'select'
    enable_completion = true,      -- Enable completion (default: true)
  },
  keys = {
    { '<leader>nn', '<cmd>NoteNew<cr>', desc = 'New note' },
    { '<leader>nf', '<cmd>NoteFind<cr>', desc = 'Find note' },
    { '<leader>ns', '<cmd>NoteSearch<cr>', desc = 'Search notes' },
    { '<leader>nb', '<cmd>NoteBacklinks<cr>', desc = 'Show backlinks' },
    { '<leader>ni', '<cmd>NoteIndex<cr>', desc = 'Index vault' },
    { '<leader>nl', '<cmd>NoteLink<cr>', desc = 'Insert link' },
  },
  cmd = { 'NoteNew', 'NoteFind', 'NoteSearch', 'NoteBacklinks', 'NoteIndex', 'NoteInit', 'NoteLink' },
  ft = 'markdown',
}
```

## Commands

- `:NoteNew [name]` - Create a new note
- `:NoteFind` - Find notes using picker
- `:NoteSearch [query]` - Search notes with SQL-style queries
- `:NoteBacklinks` - Show backlinks to current note
- `:NoteIndex[!]` - Index vault (! to force reindex)
- `:NoteInit [path]` - Initialize a new vault
- `:NoteLink` - Insert a wiki-link to another note

## Completion

The plugin supports three completion frameworks:

### Omnifunc (Built-in)
Works out of the box. Trigger with `<C-X><C-O>` after typing `[[` or `#`.

### nvim-cmp
Auto-detected and configured if installed. No additional setup needed.

### blink.cmp
Add snot to your blink.cmp sources:

```lua
{
  'saghen/blink.cmp',
  opts = {
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'snot' },
      providers = {
        snot = {
          name = 'Snot',
          module = 'snot.completion.blink',
          enabled = function()
            return vim.bo.filetype == 'markdown'
          end,
        },
      },
    },
  },
}
```

## Configuration

### Default Configuration

```lua
{
  vault_path = vim.fn.getcwd(),  -- Current directory
  snot_bin = 'snot',             -- snot binary in PATH
  picker = 'auto',               -- Auto-detect picker
  enable_completion = true,      -- Enable completion
}
```

### Picker Options

- `'auto'` - Auto-detect (tries fzf-lua, then telescope, then vim.ui.select)
- `'fzf-lua'` - Use fzf-lua (recommended)
- `'telescope'` - Use telescope.nvim
- `'select'` - Use vim.ui.select (built-in)

## Query Syntax

Search notes using SQL-style queries:

```sql
-- Basic queries
tags CONTAINS 'work'
content LIKE '%meeting%'
links_to = 'project-plan'
modified_date BETWEEN '2025-01-01' AND '2025-01-31'

-- Boolean logic
tags CONTAINS 'work' AND content LIKE '%deadline%'
tags CONTAINS 'meeting' OR tags CONTAINS 'standup'
tags CONTAINS 'work' AND NOT tags CONTAINS 'archived'

-- Grouping
(tags CONTAINS 'work' OR tags CONTAINS 'personal') AND NOT tags CONTAINS 'archived'
```

See [Query Syntax Guide](https://github.com/yourusername/snot/blob/master/docs/query-syntax.md) for more details.

## License

MIT
