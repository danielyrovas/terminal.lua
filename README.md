# terminal.lua

See more in a [blog post](https://danielyrovas.com/build-your-own-terminal.lua).

Adds several niceties to the neovim's `:terminal`:
- double escape to exit insert mode
- automatically enter insert mode
- ctrl j/k/l/h mappings to navigate
- toggle terminals via keybinds

# Installation

<details>
<summary>lazy.nvim</summary>

```lua
return {
    url = "https://tangled.org/danielyrovas.tngl.sh/terminal.lua",
    event = { "TermOpen", "VeryLazy" },
    keys = function()
        local keys = {}

        for i = 1, 9 do
            for float, key in pairs { [false] = "<c-\\>", [true] = "<c-,>" } do
                table.insert(keys, {
                    i .. key,
                    function()
                        require("terminal").toggle {
                            id = tostring(i),
                            float = float,
                        }
                    end,
                    mode = { "n", "t" },
                    desc = string.format(
                        "Toggle %s term %d",
                        float and "float" or "split",
                        i
                    ),
                })
            end
        end

        vim.list_extend(keys, {
            {
                "<c-\\>",
                function() require("terminal").toggle_last() end,
                mode = { "n", "t" },
                desc = "Toggle split term",
            },
            {
                "<c-,>",
                function() require("terminal").toggle_last { float = true } end,
                mode = { "n", "t" },
                desc = "Toggle float term",
            },
            {
                "<leader>gi",
                function()
                    require("terminal").toggle { cmd = "jjui", float = true }
                end,
                desc = "Toggle floating jjui",
            },
        })

        return keys
    end,
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
-- n<c-\> opens split terminal n, n<c-,> opens float terminal n (where n is 1–9)
for i = 1, 9 do
    for float, key in pairs { [false] = "<c-\\>", [true] = "<c-,>" } do
        vim.keymap.set({ "n", "t" }, i .. key, function()
            require("terminal").toggle { id = tostring(i), float = float }
        end, { desc = string.format("Toggle %s term %d", float and "float" or "split", i) })
    end
end

-- Toggle most recently used split / float terminal
vim.keymap.set({ "n", "t" }, "<c-\\>", function()
    require("terminal").toggle_last()
end, { desc = "Toggle split term" })

vim.keymap.set({ "n", "t" }, "<c-,>", function()
    require("terminal").toggle_last { float = true }
end, { desc = "Toggle float term" })

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
