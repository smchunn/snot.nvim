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
  cmd = { "SnotNew", "SnotFind", "SnotBacklinks", "SnotIndex", "SnotTags", "SnotGraph", "SnotLink" },
  opts = {
    vault_path = "~/notes",
  },
}
```

### Local development

```lua
{
  dir = "~/dev/snot.nvim",
  cmd = { "SnotNew", "SnotFind", "SnotBacklinks", "SnotIndex", "SnotTags", "SnotGraph", "SnotLink" },
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
| `:SnotFind [query]` | Optional query | — | Browse and search notes. Plain text fuzzy-filters locally; symbol prefixes query the backend live. |
| `:SnotNew [name]` | Optional title | `!` picks template | Create a note. Prompts for name if omitted. `SnotNew!` opens template picker first. |
| `:SnotBacklinks` | — | — | Show backlinks to the current note |
| `:SnotIndex` | — | `!` forces reindex | Index the vault. `SnotIndex!` forces full reindex. |
| `:SnotTags` | — | — | Browse tags. Selecting a tag searches for it. |
| `:SnotGraph [sub]` | `neighbors` / `orphans` / `stats` | — | Graph operations. Default: neighbors of current note. |
| `:SnotLink` | — | — | Pick a note and insert `[[link]]` at cursor |

## Query Syntax

`:SnotFind` uses a live picker — results update as you type. **Plain text** (no prefixes) lists all notes and the picker fuzzy-filters locally. **Symbol prefixes** trigger backend queries:

| Symbol | Meaning | Example | Translates to |
|--------|---------|---------|---------------|
| `#` | Tag | `#work` | `tag:work` |
| `~` | Fuzzy title | `~meting` | `~meting` |
| `*` | Full-text content | `*quarterly` | `content:quarterly` |
| `@` | Links to | `@project-plan` | `links_to:project-plan` |
| `^` | Orphans | `^` | `orphans` |
| `!` | Raw passthrough | `!tag:work OR content:plan` | `tag:work OR content:plan` |

**Combinators:**

| Symbol | Meaning | Example | Translates to |
|--------|---------|---------|---------------|
| `\|` | OR | `#work \| #personal` | `tag:work OR tag:personal` |
| `&` | AND | `#work & *quarterly` | `tag:work content:quarterly` |

Bare words mixed with prefixes default to title search: `#work & hello` becomes `tag:work title:hello`.

**Examples:**
```
meeting notes          → fuzzy filter over all notes (local)
#work                  → backend: tag:work
#work | ~meeting       → backend: tag:work OR ~meeting
#work & *quarterly     → backend: tag:work content:quarterly
^                      → backend: orphans
!neighbors:note:2      → backend: neighbors:note:2 (raw passthrough)
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
