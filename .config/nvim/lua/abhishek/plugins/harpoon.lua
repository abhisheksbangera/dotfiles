return {
  'ThePrimeagen/harpoon',

  config = function()
    require('harpoon').setup({
       global_settings = {
        -- sets the marks upon calling `toggle` on the ui, instead of require `:w`.
       save_on_toggle = false,

        -- saves the harpoon file upon every change. disabling is unrecommended.
        save_on_change = true,

        -- sets harpoon to run the command immediately as it's passed to the terminal when calling `sendCommand`.
        enter_on_sendcmd = false,

        -- closes any tmux windows harpoon that harpoon creates when you close Neovim.
        tmux_autoclose_windows = false,

        -- filetypes that you want to prevent from adding to the harpoon list menu.
        excluded_filetypes = { "harpoon" },

        -- set marks specific to each git branch inside git repository
        -- Each branch will have it's own set of marked files
        mark_branch = true,

        -- enable tabline with harpoon marks
        tabline = false,
        tabline_prefix = "   ",
        tabline_suffix = "   ",
    },
    menu = {
        width = vim.api.nvim_win_get_width(0) - 40,
      }
    })
    vim.keymap.set('n', '<leader>hx', require('harpoon.mark').add_file, { desc = "harpoon add file" })
    vim.keymap.set('n', '<leader>hn', require('harpoon.ui').nav_next, { desc = "harpoon nav next" })
    vim.keymap.set('n', '<leader>hp', require('harpoon.ui').nav_prev, { desc = "harpoon nav prev" })
    vim.keymap.set('n', '<leader>hh', require('harpoon.ui').toggle_quick_menu, { desc = "harpoon toggle menu" })
    vim.keymap.set("n", "<leader>hm", "<cmd>Telescope harpoon marks<CR>", opts)

    vim.keymap.set('n', '<leader>1',function() require('harpoon.ui').nav_file(1) end, { desc = "harpoon nav file 1" })
    vim.keymap.set('n', '<leader>2',function() require('harpoon.ui').nav_file(2) end, { desc = "harpoon nav file 2" })
    vim.keymap.set('n', '<leader>3',function() require('harpoon.ui').nav_file(3) end, { desc = "harpoon nav file 3" })
    vim.keymap.set('n', '<leader>4',function() require('harpoon.ui').nav_file(4) end, { desc = "harpoon nav file 4" })
    vim.keymap.set('n', '<leader>5',function() require('harpoon.ui').nav_file(5) end, { desc = "harpoon nav file 5" })
  end,
}
