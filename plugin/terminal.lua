vim.api.nvim_create_autocmd("TermOpen", {
    callback = function(ev)
        local buf = ev.buf
        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })

        -- only apply to user-opened terminals (blank filetype) and any other filetypes specified here (add more to include)
        if ft ~= "" then return end

        -- automatically open in insert mode
        vim.cmd.startinsert()

        -- auto-close terminal buffer on process exit
        vim.api.nvim_create_autocmd("TermClose", {
            buffer = buf,
            once = true,
            callback = function()
                if not vim.api.nvim_buf_is_valid(buf) then return end

                local win = vim.fn.bufwinid(buf)
                if win == -1 then return end

                local ok, config = pcall(vim.api.nvim_win_get_config, win)
                if not ok or not config then return end

                local is_floating = config.relative ~= ""

                local terminal = require "terminal"
                if terminal.last_terminal_buf { float = is_floating } == buf then
                    terminal.set_last_terminal_id(nil, is_floating)
                end

                vim.schedule(
                    function() pcall(vim.api.nvim_buf_delete, buf, { force = true }) end
                )
            end,
        })

        -- navigation keymaps: <c-h/j/k/l> to move between windows
        vim.keymap.set("t", "<c-h>", "<c-\\><c-n><c-w>h", { buffer = buf, noremap = true })
        vim.keymap.set("t", "<c-j>", "<c-\\><c-n><c-w>j", { buffer = buf, noremap = true })
        vim.keymap.set("t", "<c-k>", "<c-\\><c-n><c-w>k", { buffer = buf, noremap = true })
        vim.keymap.set("t", "<c-l>", "<c-\\><c-n><c-w>l", { buffer = buf, noremap = true })

        -- double-escape to exit insert mode
        vim.keymap.set(
            "t",
            "<esc><esc>",
            function() vim.cmd.stopinsert() end,
            { buffer = buf, noremap = true }
        )

        -- close terminal with 'q' in normal mode
        vim.keymap.set("n", "q", ":q<cr>", { buffer = buf, noremap = true })
    end,
})

vim.api.nvim_create_autocmd("WinEnter", {
    callback = function(ev)
        local buf = ev.buf
        local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
        -- only apply to terminal buftypes
        if buftype ~= "terminal" then return end

        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
        -- only apply to user-opened terminals (blank filetype) and any other filetypes specified here (add more to include)
        if ft ~= "" then return end

        -- automatically enter insert mode
        vim.cmd.startinsert()
    end,
})

-- Remember the last digit typed in terminal mode. Digits can't be mapped in
-- terminal mode without delaying every keystroke by 'timeoutlen', so watch the
-- raw input instead and treat a recent digit as a count for the toggle keys
-- (see `toggle_count` in lua/terminal.lua). The watcher only runs while in
-- terminal mode.
local digit_ns = vim.api.nvim_create_namespace "terminal_digit"

vim.api.nvim_create_autocmd("TermEnter", {
    callback = function()
        -- Only printable single characters are considered: the toggle keys
        -- themselves arrive as control/escape sequences (and on_key fires
        -- *before* the mapping runs), so anything non printable has to be left
        -- alone or it would clear the digit it is meant to consume.
        vim.on_key(function(_, typed)
            pcall(function()
                if typed == nil or typed == "" then return end
                local byte = typed:byte()
                local printable = #typed == 1 and byte >= 0x20 and byte < 0x7f
                if not printable then return end

                require("terminal").set_pending_digit(typed:match "^%d$")
            end)
        end, digit_ns)
    end,
})

vim.api.nvim_create_autocmd("TermLeave", {
    callback = function()
        vim.on_key(nil, digit_ns)
        require("terminal").set_pending_digit(nil)
    end,
})
