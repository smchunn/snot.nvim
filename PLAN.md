# snot.nvim — Plan

## Problem Statement

Neovim plugin for the [snot](https://github.com/smchunn/snot) CLI — a personal knowledge management tool. Provides fuzzy finding, graph traversal, template-based note creation, and auto-indexing from within Neovim.

## Architecture

```
plugin/snot.lua          -- User commands (SnotNew, SnotFind, etc.)
lua/snot/init.lua        -- setup(), config, auto-update autocmd
lua/snot/config.lua      -- Config schema + validation
lua/snot/commands.lua     -- Command dispatch + handlers
lua/snot/picker.lua       -- Picker abstraction (fzf-lua, snacks, telescope, vim.ui.select)
lua/snot/query.lua        -- Symbol-based query parser for SnotFind
lua/snot/backend.lua      -- Async CLI wrapper (jobstart)
lua/snot/templates.lua    -- Template loading, variable expansion
lua/snot/utils.lua        -- Path/ID helpers
```

### Key Decisions

- **Picker abstraction**: All pickers go through `picker.pick()` (static) or `picker.pick_live()` (dynamic). Backend-agnostic — fzf-lua, snacks, telescope, and vim.ui.select all supported.
- **Query parser**: `SnotFind` uses symbol prefixes (`#`, `~`, `*`, `@`, `^`, `!`) to translate user input into snot CLI query syntax. Plain text triggers local fuzzy filtering; prefixed input triggers backend queries.
- **Sync CLI calls in live search**: `pick_live`'s search function uses `vim.fn.system()` (synchronous) since fzf-lua's `fzf_live` expects synchronous return values. Async `backend.run_command()` is used everywhere else.

## Implementation Phases

### Phase 1: Core Plugin ✅

- Plugin structure, config, setup
- Backend CLI wrapper (async jobstart)
- Picker abstraction (static pick)
- Commands: SnotNew, SnotFind, SnotBacklinks, SnotIndex, SnotTags, SnotLink
- Template system with variable expansion
- Auto-indexing on BufWritePost

### Phase 2: Graph + Live Picker ✅

- Graph commands: neighbors, orphans, stats
- Live-search picker (`pick_live`) for all backends
- File previewer support in fzf-lua and telescope

### Phase 3: Query Parser ✅

- Symbol-based query translation layer (`lua/snot/query.lua`)
- Unified SnotFind command (merged SnotFind + SnotSearch)
- Symbol mappings: `#tag`, `~fuzzy`, `*content`, `@links_to`, `^orphans`, `!raw`
- Combinators: `|` (OR), `&` (AND)
- Bare words in query mode default to `title:` search
- Plain text (no prefixes) lists all notes for local fuzzy filter

### Phase 4: Polish & UX (Pending)

- [ ] Update README to remove SnotSearch references, document query syntax symbols
- [ ] `$` prefix reserved for structured frontmatter search (when snot CLI adds support)
- [ ] Debounce live search queries to reduce CLI calls on fast typing
- [ ] Error display in picker (e.g. invalid query feedback)
- [ ] Keybinding defaults / which-key integration
- [ ] Health check (`:checkhealth snot`)
