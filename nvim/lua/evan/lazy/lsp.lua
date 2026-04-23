return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "saghen/blink.cmp",
        "nvim-telescope/telescope.nvim"
    },

    config = function()
        require("mason").setup()
        require("mason-lspconfig").setup {
            ensure_installed = {
                "lua_ls",
                "rust_analyzer",
                "gopls",
                "docker_language_server",
                "docker_compose_language_service"
            },
            -- jdtls is managed by nvim-jdtls (start_or_attach with custom cmd for lombok).
            -- Excluding it here prevents mason-lspconfig's automatic_enable from starting
            -- jdtls via vim.lsp.enable, which would use the plugin's lsp/jdtls.lua config
            -- (cmd = {"jdtls"}, no javaagent) and cause start_or_attach to reuse that client.
            automatic_enable = {
                exclude = { "jdtls" },
            },
        }
        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "LSP references" })
        vim.keymap.set("n", "gi", builtin.lsp_implementations, { desc = "LSP implementations" })
        vim.keymap.set("n", "gD", builtin.lsp_type_definitions, { desc = "LSP type definitions" })
        vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, { desc = "Document symbols" })
        vim.keymap.set("n", "<leader>ws", builtin.lsp_workspace_symbols, { desc = "Workspace symbols" })
        vim.keymap.set("n", "ga", vim.lsp.buf.code_action, { desc = "Code actions" })
        vim.diagnostic.config({
            virtual_text = { severity = { min = vim.diagnostic.severity.WARN } },
            underline = { severity = { min = vim.diagnostic.severity.HINT } },
        })
        -- Use undercurl (wavy underline) for diagnostics instead of straight underline.
        -- Requires terminal support (Kitty, WezTerm, iTerm2, etc.).
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "Red" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = "Yellow" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = "Cyan" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "LightGrey" })
        vim.lsp.inlay_hint.enable()
    end
}
