return { 'sindrets/diffview.nvim', 
  config = function ()
    require("diffview").setup({})
    vim.opt.fillchars:append { diff = "╱" }
    vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diffview open" })
    vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "File history" })
    vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Repo history" })
    vim.keymap.set("n", "<leader>gq", "<cmd>DiffviewClose<cr>", { desc = "Diffview close" })
  end
}
