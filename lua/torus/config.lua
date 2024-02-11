local M = {}

M.namespace = "torus"

M.config = {}

function M.get(key)
  return M.config[key]
end

local defaults = {
  debug = true,
  auto_add_current_file = true,
  auto_open_preview = true,
  highlights = {
    TorusCurrentFile = { link = "SpecialChar" },
    TorusAlternateFile = { link = "Comment" }
  },
  cache_key = function()
    return vim.loop.cwd()
  end,
  cache_path = function()
    return vim.fn.stdpath("cache") .. "/torus"
  end,
}

function M.setup(opts)
  M.values = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

M.setup()

return M
