# torus.nvim

## Installation

With `lazy`:

```lua
{
  "srcrip/torus.nvim",
  config = function()
    local torus = require("torus")
    torus.setup()

    vim.keymap.set("n", "<cr>", torus.ui.open_window, { desc = "Toggle Torus" })
    vim.keymap.set("n", "<tab>", torus.ring.next, { desc = "Next buffer in ring" })
    vim.keymap.set("n", "<s-tab>", torus.ring.previous, { desc = "Previous buffer in ring" })
  end,
}
```
