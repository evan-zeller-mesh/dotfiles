return {
    {
        'nvim-telescope/telescope.nvim',
        version = '*',
        dependencies = {
            'nvim-lua/plenary.nvim',
            -- optional but recommended
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
            { 'nvim-telescope/telescope-dap.nvim' },
            { 'nvim-telescope/telescope-ui-select.nvim' },
        },
        config = function()
            require('telescope').setup({})
            require('telescope').load_extension('dap')
            require('telescope').load_extension('ui-select')
            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
            vim.keymap.set('n', '<leader>ps', builtin.live_grep, {})
        end
    }
}
