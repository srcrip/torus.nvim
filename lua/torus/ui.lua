local M = {}

local config = require("torus.config").values
local ring = require("torus.ring")
local utils = require("torus.utils")

function M.open_window()
  local alternate_file = utils.buffer_to_path('#')
  -- check alternate file before moving into the buffer
  local current_file = utils.buffer_to_path("%")
  local alternate = vim.fn.bufnr('#')
  local alternate_buf_path = ""
  local alternate_buf_file_name = ""
  if alternate ~= -1 then
    alternate_buf_path = vim.api.nvim_buf_get_name(alternate)
    alternate_buf_file_name = vim.fn.fnamemodify(alternate_buf_path, ":t")
  end

  local cache_content = ring.read_or_init_cache()

  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, cache_content)

  local width = math.min(80, vim.fn.winwidth(0) - 4)
  local height = math.min(20, #cache_content + 2)

  local row = math.ceil((vim.o.lines - height) / 2)
  local col = math.ceil((vim.o.columns - width) / 2)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    focusable = true,
    border = "rounded",
    title = "<cr> - open file, t - toggle current file, q or <esc> - close",
    title_pos = "center"
  }

  -- sometimes hit an error called 'window was closed immediately' ?
  local winid = vim.api.nvim_open_win(bufnr, true, opts)

  -- apply highlights for current/alternate
  local current_index = ring.is_saved(current_file)
  if current_index then
    vim.api.nvim_buf_add_highlight(bufnr, -1, "TorusCurrentFile", current_index - 1, 0, -1)
  end

  local alternate_index = ring.is_saved(alternate_file)
  if alternate_index then
    vim.api.nvim_buf_add_highlight(bufnr, -1, "TorusAlternateFile", alternate_index - 1, 0, -1)
  end

  local close_buffer = ":lua vim.api.nvim_win_close(" .. winid .. ", {force = true})<CR>"
  vim.api.nvim_buf_set_keymap(bufnr, "n", "q", close_buffer, { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", close_buffer, { noremap = true, silent = true })

  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    vim.cmd(":edit " .. line)
  end, { noremap = true, silent = true, buffer = bufnr })


  -- without saving.  For writing there must be matching |BufWriteCmd|,
  -- |FileWriteCmd| or |FileAppendCmd| autocommands.
  -- vim.api.nvim_create_autocmd({ "BufLeave", "BufWriteCmd", "FileWriteCmd" }, {
  vim.api.nvim_create_autocmd({ "BufLeave" }, {
    buffer = bufnr,
    desc = "save cache buffer on leave",
    callback = function()
      local updated_content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local cache_path = ring.cache_file_path()
      vim.fn.writefile(updated_content, cache_path)
      ring.load_cache_file()
      vim.api.nvim_win_close(winid, { force = true })
    end,
  })

  -- no line numbers? set option?
  vim.cmd("setlocal nu")
  --
  -- the manual adding of files is sorted by order you were editing them, so the cursor already ends up in the right
  -- place, but once there are automated lists like frequency or whatever, this will need to be added in to search for
  -- the last alternate file to put the cursor on
  --  actually I don't think it does sort now that ive looekd at it more
  -- utils.debug('.*' .. alternate_buf_file_name .. '$')
  local line = vim.fn.search('.*' .. alternate_buf_file_name .. '$')

  if line == 0 then
    line = 1
  end

  -- move cursor to that line
  vim.api.nvim_win_set_cursor(winid, { line, 0 })

  -- todo: other ideas, like a ring of swaps, such that the same number of openings will always take you to and from the
  -- same file?

  -- todo: add configuration for this, could go to current file, or could go to file based on frequency or something

  -- todo: auto-add to cache on opening of the menu?
  vim.keymap.set("n", "t", function()
    ring.toggle(current_file)
    cache_content = ring.read_or_init_cache()

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, cache_content)
  end, { noremap = true, silent = true, buffer = bufnr, nowait = true })

  -- todo: just thinking out loud but I think automatic lists arent actually helpful for something like this, theyr better off with fzf or telescoe searches casue you dony know the contents. but it would be cool to add fzf/telescope add-ons to this.

  -- ok one more wild idea,
  -- if its going to be a bufferring thing, what if it used floating text to render a view of the ring in the lower
  -- bottom like https://github.com/Hajime-Suzuki/vuffers.nvim but floating instead of a little sidebar
  -- then you had one button to cycle through the ring

  return bufnr, winid
end

-- Show a floating window in the lower right corner of the screen with the current cache
function M.open_preview_window()
  -- do nothing if not preview open
  if not ring.preview_open then
    -- close ring.preview_window if it exists
    if ring.preview_window ~= nil then
      vim.api.nvim_win_close(ring.preview_window, true)
      ring.preview_window = nil
      ring.preview_buffer = nil
    end

    return
  end

  local cache_content = ring.read_or_init_cache()

  local width = 0
  for _, line in ipairs(cache_content) do
    width = math.max(width, #line)
  end
  width = math.min(80, width)
  local height = math.min(20, #cache_content)
  local row = vim.o.lines - height - 1
  local col = vim.o.columns - width - 1

  local bufnr = vim.api.nvim_create_buf(false, true)

  ring.render_preview_buffer(bufnr)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = math.max(5, width),
    height = height,
    row = row - 2,
    col = col + 1,
    focusable = false
  }

  local winid = vim.api.nvim_open_win(bufnr, false, opts)

  -- highlight group for this window
  vim.api.nvim_win_set_option(winid, "winhl", "NormalFloat:Normal")

  ring.preview_window = winid
  ring.preview_buffer = bufnr

  vim.api.nvim_create_augroup('torus_preview', { clear = true })
  vim.api.nvim_create_autocmd({ "DirChanged", "BufEnter" }, {
    pattern = '*',
    group = 'torus_preview',
    callback = function()
      if ring.preview_open and ring.preview_window ~= nil and ring.preview_buffer ~= nil then
        ring.render_preview_buffer(ring.preview_buffer)
      end
    end,
    desc = "update preview window on file changed",
  })

  -- setup an autocmd to catch the preview window being closed, and nil out the window id
  vim.api.nvim_create_autocmd({ "WinClosed", "WinLeave" }, {
    pattern = '*',
    group = 'torus_preview',
    callback = function(e)
      if e.buf == ring.preview_buffer then
        ring.preview_window = nil
        ring.preview_buffer = nil
      end
    end,
    desc = "nil out preview window on close",
  })

  return bufnr, winid
end

M.setup = function()
  -- todo: move somewhere?
  vim.api.nvim_create_user_command('Ring', function()
    M.open_window()
  end, {})

  vim.api.nvim_create_user_command('RingFloat', function()
    ring.preview_open = not ring.preview_open
    M.open_preview_window()
  end, {})

  if (config.auto_open_preview) then
    vim.api.nvim_create_autocmd({ "VimEnter" }, {
      pattern = '*',
      callback = function()
        ring.preview_open = true
        M.open_preview_window()
      end,
      desc = "auto open preview window on VimEnter",
    })
  end
end

return M
