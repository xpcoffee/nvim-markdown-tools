local M = {}

M.setup = function(opts)
  M.notes_root_path = opts.notes_root_path
  M.journal_dir_name = opts.journal_dir_name
end

local builtins = require('telescope.builtin')

local function grep_tag()
  local text = vim.fn.expand("<cWORD>")
  local next_match = string.gmatch(text, '#[a-zA-Z0-9-]+')
  print(text)

  if next_match() then
    builtins.grep_string {
      results_title = text,
      prompt_title = "Filter results",
    }
    return true
  end
  return false
end

M.picker_example = grep_tag

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local conf = require('telescope.config').values
local make_entry = require('telescope.make_entry')

M.view_files_with_tag = function(tag)
  local tag = tag or vim.fn.expand("<cWORD>")
  local next_match = string.match(tag, '#[a-zA-Z0-9-]+')
  
  if not next_match then
    print("No tag found under cursor")
    return
  end

  pickers.new({}, {
    prompt_title = "Files with tag: " .. next_match,
    finder = finders.new_oneshot_job(
      {'rg', '--vimgrep', next_match},
      {
        entry_maker = function(entry)
          local filename, lnum, col, text = entry:match("(.+):(%d+):(%d+):(.*)")
          return {
            value = entry,
            display = string.format("%s:%s\t%s", filename, lnum, text:gsub("^%s*", "")),
            ordinal = filename .. " " .. text,
            filename = filename,
            lnum = tonumber(lnum),
            col = tonumber(col),
          }
        end
      }
    ),
    previewer = conf.grep_previewer({}),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd(string.format('edit +%d %s', selection.lnum, selection.filename))
      end)
      return true
    end,
  }):find()
end

M.list_all_tags = function()
  assert(M.notes_root_path, "notes_root_path must be configured")

  local function get_all_tags()
    local command = string.format("rg -o '(^|\\s)#[a-zA-Z0-9-]+' %s --no-filename --type markdown | sed 's/^\\s*//' | sort | uniq", M.notes_root_path)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    local tags = {}
    for tag in result:gmatch("[^\r\n]+") do
      table.insert(tags, tag)
    end
    return tags
  end

  local tags = get_all_tags()

  pickers.new({}, {
    prompt_title = "All Tags",
    finder = finders.new_table {
      results = tags,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        M.view_files_with_tag(selection.value)
      end)
      return true
    end,
  }):find()
end


M.open_daily_note = function()
  assert(M.notes_root_path, "notes_root_path must be configured")
  assert(M.journal_dir_name, "journal_dir_name must be configured")

  local today = vim.fn.strftime("%Y-%m-%d")
  local daily_note_file_name = today .. ".md"
  local daily_note_file_path = vim.fn.expand(vim.fn.resolve(M.notes_root_path ..
    "/" .. M.journal_dir_name .. "/" .. daily_note_file_name))


  if (type(daily_note_file_path) == "string") then
    if vim.fn.filereadable(daily_note_file_path) == 1 then
      vim.cmd('e ' .. daily_note_file_path)
    else
      os.execute('echo "# ' .. today .. '" > ' .. daily_note_file_path)
      vim.cmd('e ' .. daily_note_file_path)
    end
  end
end

M.trigger_cursor = function()
  assert(M.notes_root_path, "notes_root_path must be configured")
  M.view_files_with_tag()
end

return M
