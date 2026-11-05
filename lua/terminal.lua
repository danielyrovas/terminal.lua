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
    local id = opts.float and last_float_terminal_id or last_terminal_id
    local term = terminals[id]
    return term and term.buf or nil
end

M.set_last_terminal_id = function(id, float)
    if float then
        last_float_terminal_id = id
    else
        last_terminal_id = id
    end
end

M.toggle = function(opts)
    opts = type(opts) == "string" and { id = opts } or opts or {}
    local id = opts.id or opts.cmd or "1"
    local float = opts.float or false
    local term = terminals[id] or { buf = nil, win = nil, float = opts.float, cmd = opts.cmd }

    -- Keep the source window's working directory before switching to the terminal window.
    local cwd = vim.fn.getcwd()
    local current_buf = vim.api.nvim_get_current_buf()
    local current_win = vim.fn.bufwinid(current_buf)
    local current_float = vim.api.nvim_win_get_config(current_win).relative ~= ""
    local is_terminal = vim.fn.getbufvar(current_buf, "&buftype") == "terminal"

    -- Only close if it's the same terminal being toggled
    if is_terminal and current_win and vim.api.nvim_win_is_valid(current_win) then
        local current_term_id = nil
        for term_id, term_data in pairs(terminals) do
            if term_data.win == current_win then
                current_term_id = term_id
                break
            end
        end

        if current_term_id == id and (current_float or float == false) then
            vim.api.nvim_win_close(0, true)
            return
        end
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

    -- Switch to different terminal if one is already open
    for term_id, term_data in pairs(terminals) do
        if term_id ~= id and term_data.win and vim.api.nvim_win_is_valid(term_data.win) then
            -- Only close if same layout type (float vs split)
            if term_data.float == float then
                vim.api.nvim_win_close(term_data.win, true)
                term_data.win = nil
                break
            end
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
        -- vsplit copies window options from the editor window, and TermOpen
        -- does not fire again for an existing terminal buffer
        vim.wo[term.win].number = false
        vim.wo[term.win].relativenumber = false
        vim.wo[term.win].signcolumn = "no"
        vim.wo[term.win].foldcolumn = "0"
    end

    -- Start terminal with command if new buffer
    if vim.fn.getbufvar(term.buf, "&buftype") ~= "terminal" then
        vim.fn.jobstart(opts.cmd or vim.fn.split(vim.o.shell), { term = true, cwd = cwd })
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
    opts.id = id or nil

    M.toggle(opts)
end

local pending = { digit = nil, at = 0 }

--- Record a digit typed in terminal mode, or clear it with nil
--- @param digit string?
M.set_pending_digit = function(digit)
    pending.digit, pending.at = digit, vim.uv.hrtime()
end

--- Consume a digit just typed into the terminal, erasing the echoed character
--- @return string? digit
local function take_digit()
    local digit = pending.digit
    pending.digit = nil
    local elapsed_ms = (vim.uv.hrtime() - pending.at) / 1e6
    if not digit or elapsed_ms > vim.o.timeoutlen then return nil end
    local chan = vim.bo.channel
    -- the shell already echoed the digit, rub it out (DEL, the usual pty erase)
    if chan > 0 then pcall(vim.api.nvim_chan_send, chan, "\127") end
    return digit
end

--- Toggle the terminal selected by a count: `3<c-\>` in normal mode or `3`
--- typed immediately before the key in terminal mode. Without a count, the
--- last used terminal is toggled.
M.toggle_count = function(opts)
    opts = opts or {}
    local id = vim.v.count > 0 and tostring(vim.v.count) or take_digit()
    if id then
        M.toggle { id = id, float = opts.float }
    else
        M.toggle_last { float = opts.float }
    end
end

return M
