-- TODO:
-- - keybinds for toggling various terminals:
-- - 2<a-w> toggle floating terminal in position 2
-- - <a-w> toggle last terminal
-- <a-\> switch terminal between float/split

-- Toggle a dedicated terminal in a vertical split with <c-\>
local terminal_buf = nil
local terminal_win = nil

local function toggle_terminal()
    -- If terminal window is open, close it
    if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
        vim.api.nvim_win_close(terminal_win, true)
        terminal_win = nil
        return
    end

    -- If terminal buffer exists, reuse it; else create a new one
    if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
        vim.cmd "vsplit"
        terminal_win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(terminal_win, terminal_buf)
        vim.cmd "startinsert"
    else
        vim.cmd "vsplit"
        terminal_win = vim.api.nvim_get_current_win()
        vim.cmd "terminal"
        terminal_buf = vim.api.nvim_win_get_buf(terminal_win)
        vim.cmd "startinsert"
    end
end

vim.keymap.set({ "n", "t" }, "<c-\\>", toggle_terminal, { noremap = true })
