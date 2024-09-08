local M = {}

M.setup = function(opts)
  M.notes_root_path = opts.notes_root_path
  M.journal_dir_name = opts.journal_dir_name
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

M.trigger_backlink = function()
  assert(M.notes_root_path, "notes_root_path must be configured")

  local node = vim.treesitter.get_node({ lang = "markdown_inline" })

  if node then
    if node:type() == "link_text" then
      local tag_name = vim.treesitter.get_node_text(node, 0)

      -- check that [[note]] exists in the inline block (markdown tree doesn't know about [[]] by default)
      local inline = node:parent():parent()
      assert(inline and inline:type() == "inline")
      local inline_content = vim.treesitter.get_node_text(inline, 0)
      local next_tag_match = inline_content.gmatch(inline_content, "[[" .. tag_name .. "]]")
      local tag_found = next_tag_match()

      if tag_found then
        print("tag found for " .. tag_name)

        -- look to see if note exists
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
  end
end

return M
