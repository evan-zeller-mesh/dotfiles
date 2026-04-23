return {
    "mfussenegger/nvim-dap",
    config = function()
        local dap = require("dap")
        local widgets = require("dap.ui.widgets")

        -- Auto-open/close REPL console with DAP sessions
        dap.listeners.after.event_initialized["dap_console"] = function()
            dap.repl.open({}, "belowright 12split")
        end
        dap.listeners.before.event_terminated["dap_console"] = dap.repl.close
        dap.listeners.before.event_exited["dap_console"] = dap.repl.close

        -- vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP continue" })
        -- vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
        -- vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "DAP step over" })
        -- vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
        -- vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "DAP step out" })
        -- vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "DAP toggle REPL" })
        -- vim.keymap.set("n", "<leader>dh", widgets.hover, { desc = "DAP hover" })
        -- vim.keymap.set("n", "<leader>df", function() widgets.centered_float(widgets.frames) end, { desc = "DAP frames" })
        -- vim.keymap.set("n", "<leader>dS", function() widgets.centered_float(widgets.scopes) end, { desc = "DAP scopes" })
    end,
}
