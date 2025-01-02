return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
      highlights = {
        init = {
          CursorLine = { bg = "#ffffff" }, -- Replace with your color
        },
      },
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    opts = {
      style = "night",
      on_colors = function(colors)
        -- colors.border = "#ff915a"
        colors.border = "orange"
      end,
    },
  },
  -- {
  --   "akinsho/bufferline.nvim",
  --   opts = {
  --       options = {
  --         mode = "tabs",
  --         separator_style = "thick",
  --         indicator = {
  --         style = 'none'
  --       },
  --       show_buffer_icons = false,
  --       show_buffer_close_icons = false,
  --       always_show_bufferline = false,
  --     },
  --   },
  -- },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        section_separators = "",
        component_separators = "|",
      },
      sections = {
        lualine_z = {
          function()
            return tostring(vim.fn.tabpagenr()) .. "/" .. tostring(vim.fn.tabpagenr("$"))
          end,
        },
      },
    },
  },
  {
    -- floating buffer name on windows
    "b0o/incline.nvim",
    config = function()
      local helpers = require("incline.helpers")
      local devicons = require("nvim-web-devicons")
      require("incline").setup({
        window = {
          padding = 0,
          margin = { horizontal = 0 },
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if filename == "" then
            filename = "[No Name]"
          end
          local ft_icon, ft_color = devicons.get_icon_color(filename)
          local modified = vim.bo[props.buf].modified
          return {
            ft_icon and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or "",
            " ",
            { filename, gui = modified and "bold,italic" or "bold" },
            " ",
            guibg = "#44406e",
          }
        end,
      })
    end,
    -- Optional: Lazy load Incline
    event = "VeryLazy",
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        timeout = 2000,
      },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        position = "right", -- Move Neo-tree to the right
        width = 30, -- Optional: Adjust the width
      },
    },
  },
}

