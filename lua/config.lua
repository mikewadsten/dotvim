-- TODO

local telescope = require("telescope")
telescope.setup({
    extensions = {
        undo = {
            -- TODO ?
            use_delta = true,
            side_by_side = true,
            -- layout_strategy = "vertical",
            layout_config = {
                preview_width = 0.6,
            },
        },
    },
})
local undo_ext_available, ext = pcall(require, "telescope._extensions.undo")
if undo_ext_available then
    telescope.load_extension("undo")
else
    print("telescope-undo not found? Let's run PlugInstall...")
    vim.fn.timer_start(50, function()
        vim.cmd([[PlugInstall]])
        telescope.load_extension("undo")
    end)
end
vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
