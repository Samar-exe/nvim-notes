# notes.nvim

A flexible, interactive note-taking plugin for Neovim that adapts to any organizational system.

## ✨ Features

- 🎯 **Interactive UI** - Visual directory and template selection
- 📁 **Flexible Structure** - Works with any organizational system (PARA, Zettelkasten, flat files, etc.)
- 📝 **Custom Templates** - Pre-built templates for different note types
- 🔍 **Powerful Search** - Full-text search with quickfix integration
- ✅ **Todo Management** - Toggle checkboxes and manage tasks
- ⚡ **Quick Capture** - Instant note creation without breaking flow
- 🎨 **Highly Customizable** - Adapt to your workflow, not the other way around

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "samar-exe/notes.nvim", -- Replace with actual repo
  config = function()
    require("notes").setup()
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "samar-exe/notes.nvim", -- Replace with actual repo
  config = function()
    require("notes").setup()
  end
}
```

### Manual Installation

1. Clone or download the repository
2. Copy `lua/notes/init.lua` to `~/.config/nvim/lua/notes/init.lua`
3. Add to your `init.lua`:

```lua
require("notes").setup()
```

## ⚙️ Setup

### Basic Setup

```lua
require("notes").setup({
  notes_dir = vim.fn.expand("~/notes/"), -- Where to store notes
})
```

### Custom Configuration

```lua
require("notes").setup({
  notes_dir = vim.fn.expand("~/my-notes/"),
  default_extension = ".md",
  
  -- Directory structure (customize to your needs)
  directories = {
    "inbox",      -- Quick capture
    "projects",   -- Active projects
    "areas",      -- Life areas
    "resources",  -- Reference material
    "archive"     -- Completed items
  },
  
  -- Custom templates
  templates = {
    default = {
      "# {title}",
      "",
      "Created: {datetime}",
      "",
    },
    
    project = {
      "# Project: {title}",
      "",
      "**Status:** Active | **Created:** {date}",
      "",
      "## Objective",
      "",
      "## Tasks",
      "- [ ] ",
      "",
      "## Notes",
      "",
    },
    
    meeting = {
      "# Meeting: {title}",
      "",
      "**Date:** {datetime}",
      "**Attendees:** ",
      "",
      "## Agenda",
      "",
      "## Notes",
      "",
      "## Action Items",
      "- [ ] ",
    }
  }
})
```

## 🗂️ Organizational Systems

Switch between popular organizational methods instantly:

```lua
-- PARA Method
:lua require("notes").switch_system("para")

-- Flat structure (everything in root)
:lua require("notes").switch_system("flat")

-- Simple categories
:lua require("notes").switch_system("simple")

-- By note type
:lua require("notes").switch_system("by_type")

-- Zettelkasten style
:lua require("notes").switch_system("zettelkasten")
```

## 🎹 Commands

| Command | Description |
|---------|-------------|
| `:NotesNew [name]` | Create new note (interactive directory & template selection) |
| `:NotesOpen` | Open existing note (with visual browser) |
| `:NotesBrowse` | Browse notes by directory |
| `:NotesList` | List all notes organized by directory |
| `:NotesDaily` | Create/open daily note |
| `:NotesQuick` | Create quick note in inbox |
| `:NotesSearch [query]` | Search across all notes |

## ⌨️ Keymaps

### Default Keymaps (in markdown files)

```lua
-- Todo management
vim.keymap.set("n", "<leader>tt", "<cmd>lua require('notes').toggle_todo()<cr>", { desc = "Toggle todo" })
vim.keymap.set("n", "<leader>ta", "<cmd>lua require('notes').add_todo()<cr>", { desc = "Add todo" })
```

### Suggested Additional Keymaps

Add these to your `init.lua` for faster access:

```lua
-- Note management
vim.keymap.set("n", "<leader>nn", "<cmd>NotesNew<cr>", { desc = "New note" })
vim.keymap.set("n", "<leader>no", "<cmd>NotesOpen<cr>", { desc = "Open note" })
vim.keymap.set("n", "<leader>nf", "<cmd>NotesSearch<cr>", { desc = "Find in notes" })
vim.keymap.set("n", "<leader>nd", "<cmd>NotesDaily<cr>", { desc = "Daily note" })
vim.keymap.set("n", "<leader>nq", "<cmd>NotesQuick<cr>", { desc = "Quick note" })
vim.keymap.set("n", "<leader>nb", "<cmd>NotesBrowse<cr>", { desc = "Browse notes" })
vim.keymap.set("n", "<leader>nl", "<cmd>NotesList<cr>", { desc = "List notes" })
```

### Which-key Integration

```lua
local wk = require("which-key")
wk.register({
  ["<leader>n"] = {
    name = "Notes",
    n = { "<cmd>NotesNew<cr>", "New note" },
    o = { "<cmd>NotesOpen<cr>", "Open note" },
    f = { "<cmd>NotesSearch<cr>", "Find in notes" },
    d = { "<cmd>NotesDaily<cr>", "Daily note" },
    q = { "<cmd>NotesQuick<cr>", "Quick note" },
    b = { "<cmd>NotesBrowse<cr>", "Browse notes" },
    l = { "<cmd>NotesList<cr>", "List notes" },
    t = {
      name = "Todo",
      t = { "<cmd>lua require('notes').toggle_todo()<cr>", "Toggle todo" },
      a = { "<cmd>lua require('notes').add_todo()<cr>", "Add todo" },
    }
  }
})
```

## 🔌 API Reference

### Core Functions

#### `setup(config)`
Initialize the plugin with custom configuration.

```lua
require("notes").setup({
  notes_dir = "~/notes/",
  directories = {"inbox", "projects"},
  templates = { ... }
})
```

#### `new_note(name, directory, template)`
Create a new note. All parameters are optional - will prompt interactively if not provided.

```lua
-- Interactive creation
require("notes").new_note()

-- With specific parameters
require("notes").new_note("My Note", "projects", "project")
```

#### `open_note()`
Open existing note with interactive selection.

```lua
require("notes").open_note()
```

#### `browse_directory()`
Browse notes by directory with interactive selection.

```lua
require("notes").browse_directory()
```

#### `search_notes(query)`
Search across all notes. If query not provided, will prompt for input.

```lua
-- Interactive search
require("notes").search_notes()

-- Direct search
require("notes").search_notes("todo")
```

#### `daily_note()`
Create or open today's daily note.

```lua
require("notes").daily_note()
```

#### `quick_note()`
Create a quick note in inbox for immediate capture.

```lua
require("notes").quick_note()
```

### Todo Functions

#### `toggle_todo()`
Toggle todo checkbox on current line.

```lua
require("notes").toggle_todo()
```

#### `add_todo()`
Add new todo item with interactive input.

```lua
require("notes").add_todo()
```

### Utility Functions

#### `switch_system(system_name)`
Switch to a predefined organizational system.

```lua
require("notes").switch_system("para")  -- PARA method
require("notes").switch_system("flat")  -- Flat structure
```

Available systems: `"flat"`, `"para"`, `"simple"`, `"by_type"`, `"zettelkasten"`

#### `list_notes()`
List all notes organized by directory in command output.

```lua
require("notes").list_notes()
```

## 📋 Template Variables

Templates support these automatic replacements:

- `{title}` - Note title (without .md extension)
- `{date}` - Current date (YYYY-MM-DD format)
- `{datetime}` - Full timestamp (YYYY-MM-DD HH:MM:SS format)

Example template:
```lua
{
  "# {title}",
  "",
  "Created: {datetime}",
  "Date: {date}",
  ""
}
```

## 🎯 Usage Examples

### Daily Workflow

```lua
-- Morning: Plan your day
:NotesDaily

-- During work: Quick capture
:NotesQuick

-- For projects: Interactive creation
:NotesNew

-- Find something: Search all notes
:NotesSearch "meeting notes"
```

### Project Management

```lua
-- Create project note
:NotesNew "API Redesign"
-- Choose "projects" directory
-- Choose "project" template

-- Later, find and update
:NotesOpen
-- Select from visual list
```

### Learning Notes

```lua
-- Create learning note
:NotesNew "PostgreSQL Basics"
-- Choose "learning" or "resources" directory
-- Choose "default" or custom "learning" template
```

## 🔧 Configuration Examples

### Minimal Setup (Flat Structure)
```lua
require("notes").setup({
  directories = {} -- Everything in ~/notes/
})
```

### PARA Method
```lua
require("notes").setup({
  directories = {
    "01-projects",
    "02-areas", 
    "03-resources",
    "04-archive"
  }
})
```

### Simple Categories
```lua
require("notes").setup({
  directories = {
    "work",
    "personal",
    "learning",
    "ideas"
  }
})
```

## 📚 Dependencies

### Required
- Neovim 0.7+
- `vim.ui.select` (built-in or via UI plugin like [dressing.nvim](https://github.com/stevearc/dressing.nvim))

### Optional
- [ripgrep](https://github.com/BurntSushi/ripgrep) - For faster searching (falls back to `grep`)
- [which-key.nvim](https://github.com/folke/which-key.nvim) - For keymap descriptions

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- Inspired by various note-taking methodologies (PARA, Zettelkasten, etc.)
- Built for the Neovim ecosystem with modern Lua practices
