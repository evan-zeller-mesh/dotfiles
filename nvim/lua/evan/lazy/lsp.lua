return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "saghen/blink.cmp"
    },

    config = function()
        require("mason").setup()
        require("mason-lspconfig").setup {
            ensure_installed = {
                "lua_ls",
                "rust_analyzer",
                "gopls",
                "jdtls",
                "docker_language_server",
                "docker_compose_language_service"
            }
        }
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("lsp", { clear = true }),
            callback = function(args)
                vim.api.nvim_create_autocmd("BufWritePre", {
                    buffer = args.buf,
                    callback = function()
                        vim.lsp.buf.format { async = false, id = args.data.client_id }
                    end,
                })
            end
        })
        -- vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition)
        -- vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
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
