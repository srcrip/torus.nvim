-- telescope integration
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values

-- telescope integration for viewing cache

vim.api.nvim_create_user_command('RingTelescope', function()
  pickers.new({}, {
    prompt_title = "Ring",
    finder = finders.new_table(vim.g.torus_files),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local enter = function()
        local selection = require("telescope.actions.state").get_selected_entry()
        -- vim.print(vim.inspect(selection))
        -- M.go_to(selection)

        require("telescope.actions").close(prompt_bufnr)

        -- goto the file name
        M.go_to_filename(selection.value)
      end
      map("i", "<CR>", enter)
      map("n", "<CR>", enter)
      return true
    end,
  }):find()
end, {})


-- vim.api.nvim_create_user_command(
--   'RingTelescope',
--   function(opts)
--     local cache_path = cache_file_path()
--     local cache_content = vim.fn.readfile(cache_path)
--
--     local width = 0
--     for _, line in ipairs(cache_content) do
--       width = math.max(width, #line)
--     end
--     width = math.min(80, width)
--     local height = math.min(20, #cache_content)
--     local row = vim.o.lines - height - 1
--     local col = vim.o.columns - width - 1
--
--     local preview = function(prompt_bufnr)
--       local entry = require("telescope.actions.state").get_selected_entry()
--       vim.cmd(":edit " .. entry.value)
--       vim.api.nvim_win_close(prompt_bufnr, true)
--     end
--
--     pickers.new(conf, {
--       prompt_title = "Ring",
--       finder = finders.new_table(cache_content),
--       sorter = conf.generic_sorter({}),
--       attach_mappings = function(_, map)
--         map("i", "<CR>", preview)
--         return true
--       end,
--     }):find()
--   end,
--   {
--     nargs = 0,
--     force = true
--   }
-- )

-- choose_colors = function()
--   local actions = require "telescope.actions"
--   local actions_state = require "telescope.actions.state"
--   local pickers = require "telescope.pickers"
--   local finders = require "telescope.finders"
--   local sorters = require "telescope.sorters"
--   local dropdown = require "telescope.themes".get_dropdown()
--
--   function enter(prompt_bufnr)
--     local selected = actions_state.get_selected_entry()
--     local cmd = 'colorscheme ' .. selected[1]
--     vim.cmd(cmd)
--     actions.close(prompt_bufnr)
--   end
--
--   -- local colors = vim.fn.getcompletion("", "color")
--
--   local opts = {
--
--     finder = finders.new_table { "gruvbox", "nordfox", "nightfox", "monokai", "tokyonight" },
--     -- finder = finders.new_table(colors),
--     sorter = sorters.get_generic_fuzzy_sorter({}),
--
--     attach_mappings = function(prompt_bufnr, map)
--       map("i", "<CR>", enter)
--       return true
--     end,
--
--   }
--
--   local colors = pickers.new(dropdown, opts)
--
--   colors:find()
-- end
