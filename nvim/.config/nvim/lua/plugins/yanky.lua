return {
  "gbprod/yanky.nvim",
  opts = {
    highlight = {
      on_yank = true,
      higroup = "YankyYanked",
      timer = 150,  -- ✅ reduce this (default is 500ms)
    },
  },
}