# terminal.lua

See more in a [blog post](https://danielyrovas.com/build-your-own-terminal.lua).

Adds several niceties to the neovim's `:terminal`:
- double escape to exit insert mode
- automatically enter insert mode
- ctrl j/k/l/h mappings to navigate
- `q` in normal mode to close
- automatically close when the process exits
- toggle terminals via keybinds

# Installation

<details>
<summary>lazy.nvim</summary>

```lua
return {
    "danielyrovas/terminal.lua", -- or url = "https://tangled.org/danielyrovas.tngl.sh/terminal.lua",
    event = { "TermOpen", "VeryLazy" },
    keys = {
        -- `3<c-\>` (normal mode) or `3` then `<c-\>` (terminal mode) toggles terminal 3,
        -- without a count the most recently used terminal is toggled
        {
            "<c-\\>",
            function() require("terminal").toggle_count() end,
            mode = { "n", "t" },
            desc = "Toggle split term (selects recent or [count])",
        },
        {
            "<c-,>",
            function() require("terminal").toggle_count { float = true } end,
            mode = { "n", "t" },
            desc = "Toggle float term (selects recent or [count])",
        },
        {
            "<leader>gi",
            function() require("terminal").toggle { cmd = "jjui", float = true } end,
            desc = "Toggle floating jjui",
        },
    },
}
```

</details>

<details>
<summary>Manual</summary>

- Find your NeoVim config directory (probably `~/.config/nvim`)
- Copy `lua/terminal.lua` -> `~/.config/nvim/lua/terminal.lua`: Plugin functions and state (e.g. `toggle` and `toggle_last` for use in keymaps).
- Copy `plugin/terminal.lua` ->  `~/.config/nvim/plugin/terminal.lua`: Sourced automatically by NeoVim at startup and registers `autocmds` for entering insert mode by default, a keybind for double tap escape to go to normal mode, and some navigation keybinds that work in insert mode (change these if you want!).

Then add keybinds in your `init.lua`:

```lua
vim.keymap.set({ "n", "t" }, "<c-\\>", function()
    require("terminal").toggle_count()
end, { desc = "Toggle split term (selects recent or [count])" })

vim.keymap.set({ "n", "t" }, "<c-,>", function()
    require("terminal").toggle_count { float = true }
end, { desc = "Toggle float term (selects recent or [count])" })

-- Example: open a specific command in a floating terminal
vim.keymap.set("n", "<leader>gi", function()
    require("terminal").toggle { cmd = "jjui", float = true }
end, { desc = "Toggle floating jjui" })
```

</details>

# Free Software

All code in this repository is Free Software dual-licensed under either:

    MIT License (LICENSE-MIT or http://opensource.org/licenses/MIT)
    Apache License, Version 2.0 (LICENSE-APACHE or http://www.apache.org/licenses/LICENSE-2.0)

at your option.

The Software is provided “as is”, without warranty of any kind. In no event shall the authors or copyright holders be liable for any claim, damages or other liability in connection with the Software.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
