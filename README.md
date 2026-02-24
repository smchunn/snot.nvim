# snot.nvim

Neovim plugin for [SNOT](https://github.com/smchunn/snot) (Simple Note Organization Tool). Provides fuzzy finding, graph traversal, template-based note creation, and auto-indexing — all powered by the `snot` CLI.

## Requirements

- Neovim >= 0.10
- [snot](https://github.com/smchunn/snot) CLI installed and on `$PATH`
- One of: [fzf-lua](https://github.com/ibhagwan/fzf-lua), [snacks.nvim](https://github.com/folke/snacks.nvim), [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim), or built-in `vim.ui.select`

## Installation

### lazy.nvim

```lua
{
  "smchunn/snot.nvim",
  dependencies = {
    -- Pick one (or none for vim.ui.select fallback):
    -- "ibhagwan/fzf-lua",
    -- "folke/snacks.nvim",
    -- "nvim-telescope/telescope.nvim",
  },
  cmd = { "SnotNew", "SnotFind", "SnotSearch", "SnotBacklinks", "SnotIndex", "SnotTags", "SnotGraph", "SnotLink" },
  opts = {
    vault_path = "~/notes",
  },
}
```

### Local development

```lua
{
  dir = "~/dev/snot.nvim",
  cmd = { "SnotNew", "SnotFind", "SnotSearch", "SnotBacklinks", "SnotIndex", "SnotTags", "SnotGraph", "SnotLink" },
  opts = {
    vault_path = "~/notes",
  },
}
```

## Configuration

```lua
require("snot").setup({
  vault_path = "~/notes",        -- REQUIRED: path to your vault
  snot_bin = "snot",             -- path to snot binary (default: "snot")
  picker = "auto",               -- "auto" | "fzf-lua" | "snacks" | "telescope" | "select"
  templates = {
    dir = "templates",           -- directory inside vault for templates
    default = "default.md",      -- default template filename
  },
})
```

**Picker auto-detection order:** fzf-lua → snacks → telescope → vim.ui.select

## Commands

| Command | Args | Bang | Description |
|---------|------|------|-------------|
| `:SnotNew [name]` | Optional title | `!` picks template | Create a note. Prompts for name if omitted. `SnotNew!` opens template picker first. |
| `:SnotFind` | — | — | Browse all notes, select to open |
| `:SnotSearch [query]` | Optional query | — | Search with snot query syntax. Prompts if omitted. |
| `:SnotBacklinks` | — | — | Show backlinks to the current note |
| `:SnotIndex` | — | `!` forces reindex | Index the vault. `SnotIndex!` forces full reindex. |
| `:SnotTags` | — | — | Browse tags. Selecting a tag searches for it. |
| `:SnotGraph [sub]` | `neighbors` / `orphans` / `stats` | — | Graph operations. Default: neighbors of current note. |
| `:SnotLink` | — | — | Pick a note and insert `[[link]]` at cursor |

## Query Syntax

snot supports two query syntaxes, auto-detected:

**Shorthand** (quick CLI use):
```
tag:work
#work title:meeting
~meting              (fuzzy)
tag:work OR tag:personal
-tag:archived
```

**SQL-style** (complex queries):
```sql
tags CONTAINS 'work' AND title LIKE '%meeting%'
fuzzy LIKE 'meting'
neighbors('project-plan', 2)
```

## Templates

Place `.md` files in `{vault}/templates/`. Template variables:

| Variable | Example |
|----------|---------|
| `{{title}}` | My New Note |
| `{{id}}` | my-new-note-2025-01-15 |
| `{{date}}` | 2025-01-15 |
| `{{time}}` | 14:30:00 |
| `{{datetime}}` | 2025-01-15T14:30:00 |

**Default template** (used when no template file exists):

```markdown
---
id: {{id}}
aliases:
  - {{title}}
tags: []
---

# {{title}}

```

## Auto-indexing

When you save a markdown file inside the vault, the plugin automatically runs `snot update` to keep the database current. No manual reindexing needed for day-to-day editing.

## License

MIT
