-- mini pick integration
-- local mini_mru = function()
-- local hash = get_hash()
-- local cmd = 'command cat <(fre --sorted --store_name ' .. hash .. ") <(fd -t f) | awk '!x[$0]++'"
-- vim.fn.jobstart(cmd, {
--   stdout_buffered = true,
--   on_stdout = function(_, data)
--     table.remove(data, #data)
--     vim.print(data)
--
--     -- TODO: How to implement Ctrl-d behavior ?
--     MiniPick.start({
--       source = {
--         items = data,
--         name = 'Files MRU',
--         choose = function(item)
--           if vim.fn.filereadable(item) == 0 then return end
--           vim.fn.system('fre --add ' .. item .. ' --store_name ' .. hash)
--           MiniPick.default_choose(item)
--         end,
--       },
--     })
--   end,
-- })
-- -- local items = vim.fn.system(cmd)
-- end
--
-- vim.api.nvim_create_user_command('MiniMRU', mini_mru, {})
-- vim.keymap.set("n","<leader>pf", mini_mru, {desc="[P]ick [F]iles"})
