local M = {}
local terminals = {}
local last_terminal_id = nil
local last_float_terminal_id = nil

M.float_config = function()
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    return {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
        style = "minimal",
        border = "rounded",
    }
end

M.last_terminal_buf = function(opts)
    opts = opts or {}
    return opts.float and terminals[last_float_terminal_id].buf
        or terminals[last_terminal_id].buf
end

M.set_last_terminal_id = function(id) last_terminal_id = id end

-- TODO: toggling float should not close the split windows
M.toggle = function(opts)
    opts = opts or {}
    local id = opts.id or opts.cmd or "terminal.lua"
    local float = opts.float or false
    local cmd = opts.cmd

    local term = terminals[id] or { buf = nil, win = nil, float = false }

    local current_buf = vim.api.nvim_get_current_buf()
    if vim.fn.getbufvar(current_buf, "&buftype") == "terminal" then
        vim.api.nvim_win_close(0, true)
        return
    end

    -- Close window if open and layout matches, or if layout changed
    if term.win and vim.api.nvim_win_is_valid(term.win) then
        vim.api.nvim_win_close(term.win, true)
        term.win = nil
        if term.float == float then
            terminals[id] = term
            return
        end
    end

    -- Create buffer if needed
    if not (term.buf and vim.api.nvim_buf_is_valid(term.buf)) then
        term.buf = vim.api.nvim_create_buf(false, true)
    end

    -- Open window with appropriate layout
    if float then
        term.win = vim.api.nvim_open_win(term.buf, true, M.float_config())
    else
        vim.cmd "vsplit"
        term.win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(term.win, term.buf)
    end

    -- Start terminal with command if new buffer
    if vim.fn.getbufvar(term.buf, "&buftype") ~= "terminal" then
        if cmd then
            vim.cmd.terminal(cmd)
        else
            vim.cmd.terminal()
        end
    end

    vim.cmd "startinsert"
    term.float = float
    if float then
        last_float_terminal_id = id
    else
        last_terminal_id = id
    end
    terminals[id] = term
end

M.toggle_last = function(opts)
    opts = opts or {}
    local id = opts.float and last_float_terminal_id or last_terminal_id
    opts.id = id or "terminal.lua"

    M.toggle(opts)
end

return M
