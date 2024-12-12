return {
  -- 'AbdelrahmanDwedar/awesome-nvim-colorschemes',
  'Shatur/neovim-ayu',
  priority = 1000,
  config = function()
    local colors = require('ayu.colors')
    colors.generate(true)
    -- colors.line
    require('ayu').setup({
      mirage = true, -- Set to `true` to use `mirage` variant instead of `dark` for dark background.
      terminal = false, -- Set to `false` to let terminal manage its own colors.
      overrides = {
        -- LineNR = { fg = '#D9D9D9' }
        LineNR = { fg = colors.fg, }
      }, -- A dictionary of group names, each associated with a dictionary of parameters (`bg`, `fg`, `sp` and `style`) and colors in hex.
    })
    require('ayu').colorscheme()
  end,
}
