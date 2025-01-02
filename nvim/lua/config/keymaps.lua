-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- use jk to exit insert mode
-- vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

vim.keymap.set({ "n", "x" }, "gj", "<cmd>HopLineAC<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "x" }, "gk", "<cmd>HopLineBC<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "x" }, "gs", "<cmd>HopWord<CR>", { noremap = true, silent = true })

-- Yanky prev and next
vim.api.nvim_set_keymap("n", "<c-p>", "<Plug>(YankyPreviousEntry)", {})
vim.api.nvim_set_keymap("n", "<c-n>", "<Plug>(YankyNextEntry)", {})

-- Substitue
vim.keymap.del("n", "s")
vim.keymap.del("n", "S")
vim.keymap.del("x", "s")
vim.keymap.set("n", "s", require("substitute").operator, { desc = "Substitute with motion" })
vim.keymap.set("n", "ss", require("substitute").line, { desc = "Substitute line" })
vim.keymap.set("n", "S", require("substitute").eol, { desc = "Substitute to end of line" })
vim.keymap.set("x", "s", require("substitute").visual, { desc = "Substitute in visual mode" })

-- harpoon
vim.keymap.set("n", "<leader>hm", require("harpoon.mark").add_file, { desc = "harpoon add file" })
vim.keymap.set("n", "<M-h>", require("harpoon.ui").toggle_quick_menu, { desc = "harpoon toggle menu" })
vim.keymap.set("n", "<leader>1", function()
  require("harpoon.ui").nav_file(1)
end, { desc = "harpoon nav file 1" })
vim.keymap.set("n", "<leader>2", function()
  require("harpoon.ui").nav_file(2)
end, { desc = "harpoon nav file 2" })
vim.keymap.set("n", "<leader>3", function()
  require("harpoon.ui").nav_file(3)
end, { desc = "harpoon nav file 3" })
vim.keymap.set("n", "<leader>4", function()
  require("harpoon.ui").nav_file(4)
end, { desc = "harpoon nav file 4" })
vim.keymap.set("n", "<leader>5", function()
  require("harpoon.ui").nav_file(5)
end, { desc = "harpoon nav file 5" })


-- Copy current line and comment
vim.keymap.set("n", "yc", function()
  vim.api.nvim_feedkeys("yygccp", "m", false)
end)

vim.keymap.set("x", "<leader>y", function()
  vim.api.nvim_feedkeys('"+y', "m", false)
end, { desc = "yank to clipboard" })

-- Move cursor in insert mode
vim.keymap.set("i", "<C-f>", "<Right>", { desc = "move cursor in insert mode" })
vim.keymap.set("i", "<C-d>", "<Left>", { desc = "move cursor in insert mode" })

vim.keymap.set({ "n", "v" }, "gl", "$", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "gh", "^", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>uu", "<cmd>UndotreeToggle<CR>", { desc = "Undotree toggle side panel" }) --  Undotree toggle side panel

-- Begin search and replace with a macro
vim.keymap.set('x', 'qi', [[y<cmd>let @/=substitute(escape(@", '/'), '\n', '\\n', 'g')<cr>gvqi]])
-- Apply macro in the next instance of the search
vim.keymap.set('n', '<F8>', 'gn@i')

vim.keymap.set('n', 'x', '"_x')
vim.keymap.set('n', '<leader>o', 'i<CR><Esc>', { noremap = true, silent = true })