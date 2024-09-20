# nvim-markdown-tools

<img src="https://github.com/user-attachments/assets/8471e858-c781-4169-8813-8fe9c020a3ca" width="200px"></img>

This a neovim plugin that enhances navigation between markdown documents under a common folder.

The primary goal is to improve finding/linking notes similar to funcitonality found in the [foam VSCode plugin](https://marketplace.visualstudio.com/items?itemName=foam.foam-vscode).

## ☕ About

### Why does this exist?

Existing tooling for woriking with markdown notes (circa 2024-08) are complete notetaking or documentation systems e.g. vimwiki. I want something simpler. I have loose notes that are backlinked, and my hunch is I don't need a full system or a database to work with them effectively.

### Tenets

- Optimized for core usecases. Make a great experience for a small set of core workflows. Agressively avoid supporting more. Some effects:
  - Markdown only.
  - De-normalized note-taking only. No heirarchy with 1 exception: daily notes.
- Domain-sparse. Start with backlinks and tags. Aggressively avoid adding more.
- No database. This is for personal note-taking. Processing files on the fly is quick enough that we don't need indices and the like.
- Lean on the ecosystem. Do not build functionality here that can already be done by other plugins. e.g. grepping and finding files by name exists already. e.g.2. file-management plugins already exist.

## ⚙️ Features

Core workflows

0. Notes are in a single notes folder
1. Backlink between files using `[[my/note]]` syntax.
   - Navigate to the linked file
   - See all other files that backlink to this one within the notes folder
   - Create a new file if a backlink does not already exist
2. Add tags to files using `#mytag` syntax.
   - See all other files that have the same tag
   - Discover all tags in the notes folder
3. Daily journal files under a specified folder.
   - Go to today's journal file; create it if it doesn't yet exist.
   - Go to a journal file from the last 5 days.

| Feature                                                | Availability                                      | Command                                                          |
| ------------------------------------------------------ | ------------------------------------------------- | ---------------------------------------------------------------- |
| ~Goto note page by triggering backlink `[[backlink]]`~ | Not needed. Can be done using the `marksman` lsp. | -                                                                |
| Goto today's journal note. Create if it doesn't exist. | Y                                                 | `require "nvim-markdown-tools".open_daily_journal()`             |
| Show files with tag `#tag`.                            | Y                                                 | `require "nvim-markdown-tools".view_files_with_tag(tag)`         |
| Show all tags in notes.                                | Y                                                 | `require "nvim-markdown-tools".list_all_tags()`                  |
| Go to daily journal note.                              | Y                                                 | `require "nvim-markdown-tools".open_daily_note()`                |
| Show files backlinked to the current file.             | Y                                                 | `require "nvim-markdown-tools".list_backlinks_to_current_file()` |

## ⌨️ Installation and configuration

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "xpcoffee/nvim-markdown-tools",
  dependencies = {
    "nvim-telescope/telescope.nvim"
  },
  config = function()
    local nvim_markdown_tools = require "nvim-markdown-tools"

    nvim_markdown_tools.setup({
      -- the folder that holds the notes; tag and backlink searches happen relative to this
      notes_root_path = "~/code/notes/",
      -- the name of the folder that holds daily journals
      journal_dir_name = "journal"
    })

    -- journal actions
    vim.keymap.set("n", "<leader>nd", nvim_markdown_tools.open_daily_journal, { desc = "Open today's journal", remap = false })
    vim.keymap.set("n", "<leader>nj", nvim_markdown_tools.open_journal, { desc = "Open a journal note from the last 5 days", remap = false })
    -- backlink actions
    -- use in combination with functionality from the marksman LSP https://github.com/artempyanykh/marksman
    vim.keymap.set("n", "<leader>nb", nvim_markdown_tools.list_backlinks, { desc = "List backlinks", remap = false })
    -- tag actions
    vim.keymap.set("n", "<leader>nta", nvim_markdown_tools.list_all_tags, { desc = "List all tags", remap = false })
    vim.keymap.set("n", "<leader>ntt", nvim_markdown_tools.view_files_with_tag, { desc = "View files for tag under cursor", remap = false })
  end
}

```

## 🔍 Research

Stream of consciousness as I build this

### 2024-09-20

This is turning into a set of additional functionality for working with markdown files.
I'm thinking I should move away from implying that this is a personal knowledge management system.

Renaming to `nvim-markdown-tools`.

### 2024-09-19

I'm trying out cursor editor to help add functionality. So far it's working well, and it's showing me some good picker patterns.

### 2024-09-18

Tried out other markdown lsps and the [`marksman` lsp](https://github.com/artempyanykh/marksman) can do backlinks and even has previews using shift-k. That allows me to remove functionality from this.

One note: it's autosuggestions when typing in backlinks aren't very good. This could be nice to enhance in future..

### 2024-09-09

After writing the tenets I wonder if this should be focused to just backling & tag navigation relative to a root directory. e.g. "nvim-markdown-metadata-navigation". I just want goto-or-create & find by metadata more than that risks pulling us into creating a full system, which I don't want to do.
