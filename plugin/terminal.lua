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
