# voam

> [!caution]
> Work in progress. Not ready for consumption.

Inspired by [foam](https://marketplace.visualstudio.com/items?itemName=foam.foam-vscode) with neovim in mind.

## Features

| Feature                                                | Availability | Command                             |
| ------------------------------------------------------ | ------------ | ----------------------------------- |
| Goto note page by triggering backlink `[[backlink]]`   | Y            | `require "voam".trigger_backlink()` |
| Goto today's journal note. Create if it doesn't exist. | Y            | `require "voam".open_daily_note()`  |
| Go to yesterday's journal note.                        | N            |
| Show files backlinked to the current file.             | N            |
| Show files with tag `#tag`.                            | N            |
