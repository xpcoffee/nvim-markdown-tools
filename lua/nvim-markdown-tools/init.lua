local M = {}

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local conf = require('telescope.config').values

-- View all files in the project that contain a specific tag and show them in telescope
M.view_files_with_tag = function(tag)
  assert(M.notes_root_path, "notes_root_path must be configured")
  local next_match = string.match(tag, '#[a-zA-Z0-9-]+')

  if not next_match then
    print("No tag found under cursor")
    return
  end

  pickers.new({}, {
    prompt_title = "Files with tag: " .. next_match,
    finder = finders.new_oneshot_job(
      { 'rg', '--vimgrep', next_match },
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
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd(string.format('edit +%d %s', selection.lnum, selection.filename))
      end)
      return true
    end,
  }):find()
end

-- List all tags in the project and show them intelescope
M.list_all_tags = function()
  assert(M.notes_root_path, "notes_root_path must be configured")

  local function get_all_tags()
    local command = string.format(
      "rg -o '(^|\\s)#[a-zA-Z0-9-]+' %s --no-filename --type markdown | sed 's/^\\s*//' | sort | uniq", M
      .notes_root_path)
    local tags = {}

    local handle = io.popen(command)
    if handle == nil then
      return tags;
    end

    local result = handle:read("*a")
    handle:close()
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
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        M.view_files_with_tag(selection.value)
      end)
      return true
    end,
  }):find()
end

-- Show a telescope menu with options for what journal to open
M.open_journal = function()
  assert(M.notes_root_path, "notes_root_path must be configured")
  assert(M.journal_dir_name, "journal_dir_name must be configured")

  local function get_date_options()
    local options = {}
    for i = 0, 5 do
      local date = os.date("%Y-%m-%d", os.time() - i * 86400)
      local label = date
      if i == 0 then
        label = label .. " (today)"
      elseif i == 1 then
        label = label .. " (yesterday)"
      end
      table.insert(options, { date = date, label = label })
    end
    return options
  end

  local date_options = get_date_options()

  pickers.new({}, {
    prompt_title = "Open Journal",
    finder = finders.new_table {
      results = date_options,
      entry_maker = function(entry)
        return {
          value = entry.date,
          display = entry.label,
          ordinal = entry.label,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local journal_file_name = selection.value .. ".md"
        local journal_file_path = vim.fn.expand(vim.fn.resolve(M.notes_root_path ..
          "/" .. M.journal_dir_name .. "/" .. journal_file_name))

        if type(journal_file_path) == "string" then
          if vim.fn.filereadable(journal_file_path) == 1 then
            vim.cmd('edit ' .. journal_file_path)
          else
            os.execute('echo "# ' .. selection.value .. '" > ' .. journal_file_path)
            vim.cmd('edit ' .. journal_file_path)
          end
        end
      end)
      return true
    end,
  }):find()
end

-- Find backlinks tto this file and list them in telescope
M.list_backlinks = function()
  assert(M.notes_root_path, "notes_root_path must be configured")

  local current_file = vim.fn.expand('%:t:r')
  local backlink_pattern = '%[%[' .. current_file .. '%]%]'
  local files_with_backlinks = {}

  local function search_backlinks(file)
    local f = io.open(file, "r")
    if f then
      local content = f:read("*all")
      f:close()
      for line in content:gmatch("[^\r\n]+") do
        if line:match(backlink_pattern) then
          table.insert(files_with_backlinks, { filename = file, line = line })
          break
        end
      end
    end
  end

  for file in vim.fn.glob(M.notes_root_path .. '/**/*.md'):gmatch("[^\r\n]+") do
    search_backlinks(file)
  end

  pickers.new({}, {
    prompt_title = "Backlinks to " .. current_file,
    finder = finders.new_table {
      results = files_with_backlinks,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.filename .. ": " .. entry.line,
          ordinal = entry.filename,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local file_path = selection.value.filename
        print('opening file: ' .. file_path)
        vim.cmd('edit ' .. file_path)
        local file = io.open(file_path, "r")
        if file then
          local content = file:read("*all")
          file:close()
          local line_num = 1
          for line in content:gmatch("[^\r\n]+") do
            if line == selection.value.line then
              vim.api.nvim_win_set_cursor(0, { line_num, 0 })
              break
            end
            line_num = line_num + 1
          end
        end
      end)
      return true
    end,
  }):find()
end


-- Open today's journal entry - populate it if it doesn't exist.
M.open_daily_journal = function()
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

-- Function to extract code block languages from markdown
local function extract_code_block_languages()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local languages = {}

  for _, line in ipairs(lines) do
    local language = line:match("^```(.*)")
    if language and language ~= "" then
      table.insert(languages, language)
    end
  end

  return languages
end

local language_server_mapping = {
  csharp = "csharp_ls",
  ["c#"] = "csharp_ls",
  cs = "csharp_ls"
};

-- Map the name of languages to language servers
local function map_langage_server(language)
  local language_server = language_server_mapping[language]
  if language_server == nil then
    return language
  end
  return language_server
end

-- Function to start LSPs for the given languages
local function start_lsps_for_languages(languages)
  local lspconfig = require('lspconfig')

  for _, language in ipairs(languages) do
    local language_server = map_langage_server(language)
    if not vim.lsp.get_active_clients({ name = language_server })[1] then
      if lspconfig[language_server] then
        lspconfig[language_server].setup({})
      else
        print("No LSP configuration found for language: " .. language_server)
      end
    end
  end
end

-- Function to extract code block and its language from markdown
local function extract_code_block()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local code_block = {}
  local in_code_block = false
  local language = nil

  for _, line in ipairs(lines) do
    if line:match("^```") then
      if in_code_block then
        in_code_block = false
        break
      else
        in_code_block = true
        language = line:match("^```(.*)")
      end
    elseif in_code_block then
      table.insert(code_block, line)
    end
  end

  return table.concat(code_block, "\n"), language
end

-- Function to send code block to LSP and get response
local function send_to_lsp(code_block, language)
  local clients = vim.lsp.get_clients()
  local client_id = nil

  for _, client in ipairs(clients) do
    if client.config.filetypes and vim.tbl_contains(client.config.filetypes, language) then
      client_id = client.id
      break
    end
  end

  if not client_id then
    print("No LSP client found for language: " .. language)
    return nil
  end

  local params = {
    textDocument = {
      uri = vim.uri_from_bufnr(0)
    },
    content = code_block
  }

  local response = vim.lsp.buf_request_sync(client_id, 'textDocument/codeAction', params, 1000)
  if response and response[1] and response[1].result then
    return response[1].result[1].edit.changes[1].newText
  end

  return nil
end

-- Function to replace code block with LSP response
local function replace_code_block(new_code)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local new_lines = {}
  local in_code_block = false

  for _, line in ipairs(lines) do
    if line:match("^```") then
      in_code_block = not in_code_block
      if not in_code_block then
        table.insert(new_lines, new_code)
      end
    elseif not in_code_block then
      table.insert(new_lines, line)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end

-- Command to process code block with LSP
local function process_code_block()
  local code_block, language = extract_code_block()
  if code_block and language then
    local new_code = send_to_lsp(code_block, language)
    if new_code then
      replace_code_block(new_code)
    else
      print("LSP did not return any code.")
    end
  else
    print("No code block found or language not specified.")
  end
end

-- Setup the extension: use user configuration & set up autocommands
M.setup = function(opts)
  M.notes_root_path = opts.notes_root_path:gsub("/$", "")
  M.journal_dir_name = opts.journal_dir_name

  vim.api.nvim_create_user_command('ProcessCodeBlock', process_code_block, {})
  vim.api.nvim_create_autocmd('BufReadPost', {
    pattern = '*.md',
    callback = function()
      local languages = extract_code_block_languages()
      start_lsps_for_languages(languages)
    end
  })
end


return M
