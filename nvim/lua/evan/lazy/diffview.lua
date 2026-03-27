return { 'sindrets/diffview.nvim', 
  config = function ()
    require("diffview").setup({})
    vim.opt.fillchars:append { diff = "╱" } 
  end
}
