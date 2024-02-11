local M = {}

local config = require("torus.config")

M.ui = require("torus.ui")
M.ring = require("torus.ring")

M.config = {}

function M.setup(opts)
  config.setup(opts)
  M.ui.setup()

  for group, highlight in pairs(config.values.highlights) do
    -- no idea why you have to do this but it doesn't work without it
    highlight.default = true
    vim.api.nvim_set_hl(0, group, highlight)
  end

  M.ring.load_cache_file()

  vim.api.nvim_create_augroup("torus", { clear = true })

  -- I think reloading the cache on bufenter is a good idea, but might be good to have a config option to do it on
  -- dirchanged only
  vim.api.nvim_create_autocmd({ "DirChanged", "BufEnter" }, {
    callback = function()
      M.ring.load_cache_file()
    end,
    desc = "load cache file on DirChanged",
    group = "torus",
  })
end

return M
