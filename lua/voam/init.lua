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
  end
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

local try_trigger_backtag = function(node)
  local tag_name = vim.treesitter.get_node_text(node, 0)

  -- check that [[note]] exists in the inline block (markdown tree doesn't know about [[]] by default)
  local inline = node:parent():parent()
  assert(inline and inline:type() == "inline")
  local inline_content = vim.treesitter.get_node_text(inline, 0)
  local next_tag_match = inline_content.gmatch(inline_content, "[[" .. tag_name .. "]]")
  local tag_found = next_tag_match()

  if tag_found then
    print("tag found for " .. tag_name)

    -- look to see if markown file for the note already exists
    local file_path = vim.fn.expand(vim.fn.resolve(M.notes_root_path .. "/" .. tag_name .. ".md"))
    if (type(file_path) == "string") then
      if vim.fn.filereadable(file_path) == 1 then
        vim.cmd('e ' .. file_path)
      else
        vim.ui.select(
          { 'yes', 'no' },
          { prompt = tag_name .. ".md does not exist. Create it?" },
          function(choice)
            if choice == "yes" then
              os.execute('echo "# ' .. tag_name .. '" > ' .. file_path)
              vim.cmd('e ' .. file_path)
            end
          end
        )
      end
    else
      error("Tag resolves to multiple files. Please check that it contains no wildcards.")
    end
  end
end

M.trigger_cursor = function()
  assert(M.notes_root_path, "notes_root_path must be configured")

  local node = vim.treesitter.get_node({ lang = "markdown_inline" })

  if node then
    if node:type() == "link_text" then
      try_trigger_backtag(node)
    end
  end
end

return M
