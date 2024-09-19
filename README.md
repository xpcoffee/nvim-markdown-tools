# voam

> [!caution]
> Work in progress. Not ready for consumption.

## What

This a neovim plugin for quick navigation and creation of backlinked markdown notes.

## Why

Existing tooling I've tried (circa 2024-08) such as vimwiki and tools based off of it, are optimized to work with and manage a hierarchical documentation system, complete with its database.

I want something simpler. I have loose notes that are backlinked, and my hunch is I don't need a full system or a database to work with them effectively.

Something close to what I want exists in the [foam](https://marketplace.visualstudio.com/items?itemName=foam.foam-vscode) VSCode plugin. I feel it can be even simpler, and I want it in neovim.

## Tenets

- Personal. This is for a single-person's notes.
- Optimized for core usecases. Make a great experience for a small set of core workflows. Agressively avoid supporting more. Some effects:
  - Markdown only.
  - De-normalized note-taking only. No heirarchy with 1 exception: daily notes.
- Domain-sparse. Start with backlinks and tags. Aggressively avoid adding more.
- No database. This is for personal note-taking. Processing files on the fly is quick enough that we don't need indices and the like.
- Lean on the ecosystem. Do not build functionality here that can already be done by other plugins. e.g. grepping and finding files by name exists already. e.g.2. file-management plugins already exist.

## Features

| Feature                                                | Availability                                      | Command                            |
| ------------------------------------------------------ | ------------------------------------------------- | ---------------------------------- |
| ~Goto note page by triggering backlink `[[backlink]]`~ | Not needed. Can be done using the `marksman` lsp. | -                                  |
| Goto today's journal note. Create if it doesn't exist. | Y                                                 | `require "voam".open_daily_note()` |
| Show files with tag `#tag`.                            | Y                                               |  `require "voam".view_files_with_tag(tag)`                                   |
| Show all tags in notes.                                | Y                                               |  `require "voam".list_all_tags()`                                   |
| Go to yesterday's journal note.                        | N                                                 |                                    |
| Show files backlinked to the current file.             | N                                                 |                                    |

## Research

Stream of consciousness as I build this

### 2024-09-18

Tried out other markdown lsps and the [`marksman` lsp](https://github.com/artempyanykh/marksman) can do backlinks and even has previews using shift-k. That allows me to remove functionality from this.

One note: it's autosuggestions when typing in backlinks aren't very good. This could be nice to enhance in future..

### 2024-09-09

After writing the tenets I wonder if this should be focused to just backling & tag navigation relative to a root directory. e.g. "nvim-markdown-metadata-navigation". I just want goto-or-create & find by metadata more than that risks pulling us into creating a full system, which I don't want to do.
