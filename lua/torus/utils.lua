local M = {}

local config = require("torus.config").values

function M.buffer_to_path(buffer)
  local bufname = vim.fn.bufname(buffer)

  local cwd = vim.fn.getcwd()

  local escaped_cwd = cwd:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")

  if bufname:find("^" .. escaped_cwd .. "/") then
    local relative_path = bufname:gsub("^" .. escaped_cwd .. "/", "")
    return relative_path
  else
    return bufname
  end
end

function M.debug(x)
  if config.debug then
    vim.print(vim.inspect(x))
  end
end

return M
