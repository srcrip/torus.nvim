local M = {}

-- todo: rename file to cache
-- todo: find unused functions in here

local config = require("torus.config").values
local utils = require("torus.utils")

local preview_open = false
local preview_window = nil
local preview_buffer = nil

function M.cache_file_path()
  local path = config.cache_path()

  path = path:gsub("/$", "")

  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end

  -- make it a valid filename
  local filename = config.cache_key():gsub("/", "_")

  return path .. "/" .. filename
end

vim.g.torus_files = {}

-- todo: rename to add
function M.save(filename)
  if not M.is_saved(filename) then
    local new_table = vim.g.torus_files
    table.insert(new_table, filename)
    vim.g.torus_files = new_table

    M.cache_file()
    M.load_cache_file()
  end
end

function M.remove(filename)
  local index = M.is_saved(filename)
  if index then
    local new_table = vim.g.torus_files
    table.remove(new_table, index)
    vim.g.torus_files = new_table

    M.cache_file()
    M.load_cache_file()
  end
end

function M.toggle(filename)
  filename = filename or utils.buffer_to_path("%")

  local index = M.is_saved(filename)
  if index then
    M.remove(filename)
  else
    M.save(filename)
  end

  if preview_open and preview_window ~= nil and preview_buffer ~= nil then
    M.render_preview_buffer(preview_buffer)
  end
end

function M.clear()
  vim.g.torus_files = {}
  M.cache_file()
  M.load_cache_file()
end

function M.is_saved(filename)
  for i, name in ipairs(vim.g.torus_files) do
    if name == filename then
      return i
    end
  end
  return nil
end

function M.load_cache_file()
  local success, data = pcall(vim.fn.readfile, M.cache_file_path())
  if success then
    vim.g.torus_files = data
  else
    vim.g.torus_files = {}
  end
end

function M.cache_file()
  local content = vim.fn.join(vim.g.torus_files, "\n")
  local lines = vim.fn.split(content, "\n")
  vim.fn.writefile(lines, M.cache_file_path())
end

function M.go_to(index)
  local filename = vim.g.torus_files[index]

  if filename then
    M.go_to_filename(filename)
  end
end

function M.go_to_filename(filename)
  -- If we've already got the file open, switch to it instead of reading
  local existing = vim.fn.bufnr(filename)
  if existing ~= -1 then
    vim.cmd.buffer(existing)
    return
  end

  vim.cmd.edit(filename)
end


function M.next()
  local current_index = M.is_saved(utils.buffer_to_path("%"))
  local next_index

  if current_index and current_index < #vim.g.torus_files then
    next_index = current_index + 1
  else
    next_index = 1
  end

  M.go_to(next_index)
end

function M.previous()
  local current_index = M.is_saved(utils.buffer_to_path("%"))
  local previous_index

  if current_index and current_index == 1 then
    previous_index = #vim.g.torus_files
  elseif current_index then
    previous_index = current_index - 1
  else
    previous_index = #vim.g.torus_files
  end

  M.go_to(previous_index)
end

function M.read_or_init_cache()
  local cache_path = M.cache_file_path()

  local cache_content = {}
  local ok, res = pcall(vim.fn.readfile, cache_path)
  if not ok then
    -- utils.debug("cache file nil, creating cache_content")
    cache_content = {}

    if config.auto_add_current_file then
      local current_file = utils.buffer_to_path("%")
      table.insert(cache_content, current_file)
    end
  else
    cache_content = res
  end

  return cache_content
end

-- Open file based on index in the ring file
vim.api.nvim_create_user_command('RingIndex', function(opts)
  M.load_cache_file()
  local index = opts.fargs[1]
  M.go_to(index - 1)
end, { nargs = 1 })


function M.current_file_or_argument(opts)
  local file = utils.buffer_to_path("%")

  if opts.nargs ~= 0 then
    file = opts.fargs[1]
  end

  return file
end

vim.api.nvim_create_user_command('RingNext', M.next, {})
vim.api.nvim_create_user_command('RingPrev', M.previous, {})

vim.api.nvim_create_user_command('RingToggle', function(opts)
  M.toggle(M.current_file_or_argument(opts))
end, { nargs = "?" })

vim.api.nvim_create_user_command('RingAdd', function(opts)
  M.save(M.current_file_or_argument(opts))
end, { nargs = "?" })

vim.api.nvim_create_user_command('RingRemove', function(opts)
  M.remove(M.current_file_or_argument(opts))
end, { nargs = "?" })

vim.api.nvim_create_user_command('RingClear', M.clear, {})

-- todo: move to ui
function M.render_preview_buffer(bufnr)
  local cache_content = M.read_or_init_cache()

  local width = 0
  for _, line in ipairs(cache_content) do
    width = math.max(width, #line)
  end
  width = math.min(80, width)
  local height = math.min(20, #cache_content)

  -- right align the cache lines, with padding, to the width of the window
  cache_content = vim.tbl_map(function(line)
    return string.rep(" ", width - #line) .. line
  end, cache_content)

  -- vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, cache_content)
  -- vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  --

  -- Highlight the current file in bold
  local current_file = utils.buffer_to_path("%")
  local current_index = M.is_saved(current_file)
  if current_index then
    vim.api.nvim_buf_add_highlight(bufnr, -1, "TorusCurrentFile", current_index - 1, 0, -1)
  end

  -- -- Highlight the alternate file in italic
  local alternate_file = utils.buffer_to_path("#")
  local alternate_index = M.is_saved(alternate_file)
  if alternate_index then
    vim.api.nvim_buf_add_highlight(bufnr, -1, "TorusAlternateFile", alternate_index - 1, 0, -1)
  end

  -- set win height
  if preview_window ~= nil then
    vim.api.nvim_win_set_height(preview_window, height)
  end

  -- move window because height may have changed
  if preview_window ~= nil then
    local row = vim.o.lines - height - 1
    local col = vim.o.columns - width - 1

    vim.api.nvim_win_set_config(preview_window, {
      style = "minimal",
      relative = "editor",
      width = math.max(5, width),
      height = height,
      row = row - 2,
      col = col + 1,
      focusable = false
    })
  end
end

return M
