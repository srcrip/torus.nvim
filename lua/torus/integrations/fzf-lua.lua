-- FZFLua integration
-- local fzf = require("fzf")
--
-- vim.api.nvim_create_user_command(
--   'MRU',
--   function(opts)
--     local fzf = require 'fzf-lua'
--     print("fre --sorted --store_name " .. get_hash())
--     fzf.files({
--       -- use this if you only want stuff from fre
--       cmd         = "fre --sorted --store_name " .. get_hash(),
--       -- use this if you also want all files, but sorted by whats in fre first
--       -- cmd = "bash -c \"cat <(fre --sorted --store_name " .. get_hash() .. ") <(fd -t f) \" | awk '!a[$0]++'",
--       fzf_opts    = {
--         -- make sure that items towards top are from history
--         ['--tiebreak'] = 'index'
--       },
--       prompt      = 'fre ❯ ',
--       git_icons   = false,
--       file_icons  = false,
--       color_icons = false,
--       actions     = {
--         ['ctrl-d'] = {
--           -- Ctrl-d to remove from history
--           function(sel)
--             if #sel < 1 then return end
--             local filename = sel[1]
--             vim.fn.system('fre --delete ' .. filename .. ' --store_name ' .. get_hash())
--           end,
--           -- This will refresh the list
--           fzf.actions.resume,
--         },
--       },
--     })
--   end,
--   {
--     nargs = 0,
--     force = true
--   }
-- )


--fzf lua integration for viewing cache
vim.api.nvim_create_user_command(
  'RingFzf',
  function(opts)
    local fzf = require 'fzf-lua'
    fzf.files({
      cmd = "cat " .. cache_file_path(),
      fzf_opts = {
        ['--tiebreak'] = 'index'
      },
      prompt = 'Ring ❯ ',
      git_icons = false,
      file_icons = false,
      color_icons = false,
      -- toggle_ignore_flag = "--no-ignore",
      actions = {
        ["ctrl-g"] = false,
        ['ctrl-d'] = {
          -- Ctrl-d to remove from history
          function(sel)
            if #sel < 1 then return end
            local filename = sel[1]
            M.remove(filename)
          end,
          -- This will refresh the list
          fzf.actions.resume,
        },
      },
    })
  end,
  {
    nargs = 0,
    force = true
  }
)
