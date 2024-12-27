-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-------------------------
-- Diff with last save --
-------------------------
vim.api.nvim_create_user_command('DiffWithSaved', function()
    -- Get current buffer info
    local cur_buf = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(cur_buf)
  
    -- Check if file exists on disk
    if filename == '' or not vim.fn.filereadable(filename) then
      vim.notify('File not saved on disk!', vim.log.levels.ERROR)
      return
    end
  
    local ft = vim.bo.filetype
    local cur_lines = vim.api.nvim_buf_get_lines(cur_buf, 0, -1, false)
    local saved_lines = vim.fn.readfile(filename)
  
    -- Create new tab
    vim.cmd 'tabnew'
  
    -- Function to create and setup a scratch buffer
    local function create_scratch_buffer(lines, title)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_set_option_value('filetype', ft, { buf = buf })
      vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_set_option_value('winbar', title, { scope = 'local' })
      return buf
    end
  
    -- Create first scratch buffer with current content
    local buf1 = create_scratch_buffer(cur_lines, 'Unsaved changes')
  
    -- Create vertical split
    vim.cmd 'vsplit'
  
    -- Create second scratch buffer with saved content
    local buf2 = create_scratch_buffer(saved_lines, 'File on disk')
  
    -- Enable diff mode for both windows
    vim.cmd 'windo diffthis'
  
    -- Add keymapping to close diff view
    local function close_diff()
      vim.cmd 'tabclose'
    end
  
    vim.keymap.set('n', 'q', close_diff, { buffer = buf1, silent = true })
    vim.keymap.set('n', 'q', close_diff, { buffer = buf2, silent = true })
  end, {})
  
vim.keymap.set('n', '<leader>ds', '<cmd>DiffWithSaved<cr>', { remap = false, silent = true, desc="Diff with saved" })
