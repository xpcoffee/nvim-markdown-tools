local M = {}

M.setup = function(opts)
  M.notes_root_path = opts.notes_root_path
  M.journal_dir_name = opts.journal_dir_name
end

local builtins = require('telescope.builtin')

local function grep_tag()
  local text = vim.fn.expand("<cWORD>")
  local next_match = string.gmatch(text, '#.+')

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
local conf = require 'telescope.config'.values

function attach_mappings(prompt_bufnr, map)
  actions.select_default:replace(function()
    actions.close(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    print(selection[1])
  end)
  return true
end

M.picker_example = function(opts)
  opts = opts or { tag = "#test" } -- #test
  pickers.new(opts, {
    prompt_title = "Files matching tag",
    finder = finders.new_onetime_job {
      "ag -l " .. opts.tag,
      {
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry,
            ordinal = entry
          }
        end
      }
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = attach_mappings
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
  grep_tag()
end

return M
