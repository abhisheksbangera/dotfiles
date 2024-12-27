return {
  "mbbill/undotree",
  config = function ()
    vim.api.nvim_create_autocmd("VimResized", {
      callback = function()
        local width = math.floor(vim.o.columns * 0.3)
        vim.g.undotree_SplitWidth = width
      end,
    })
  end
}
