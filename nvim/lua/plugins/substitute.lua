return {
  "gbprod/substitute.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local substitute = require("substitute")

    substitute.setup({
      on_substitute = require("yanky.integration").substitute(),
      highlight_substituted_text = {
        enabled = true,
        timer = 150,
      },
    })

    -- vim.keymap.set("n", "s", substitute.operator, { desc = "Substitute with motion" })
    -- vim.keymap.set("n", "ss", substitute.line, { desc = "Substitute line" })
    -- vim.keymap.set("n", "S", substitute.eol, { desc = "Substitute to end of line" })
    -- vim.keymap.set("x", "s", substitute.visual, { desc = "Substitute in visual mode" })
  end,
}
