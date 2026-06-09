return {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
        require'nvim-treesitter'.install({
                "lua",
                "rust",
                "scala",
                "java",
                "bash",
                "go",
                "typescript",
                "tsx",
                "javascript",
                "json"
            })
    end
}
