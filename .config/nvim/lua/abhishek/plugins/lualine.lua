return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local lualine = require("lualine")
      local lazy_status = require("lazy.status") -- to configure lazy pending updates count
  
      -- configure lualine with modified theme
      lualine.setup({
        options = {
          -- theme = "codedark",
          theme = "ayu",
          icons_enabled = false,
          section_separators = '', 
          component_separators = '',
        },
        extensions = {'nvim-tree'}
      })
    end,
}
