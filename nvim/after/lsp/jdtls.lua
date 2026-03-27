local home = vim.fn.expand("~")
return {
    settings = {
        java = {
            configuration = {
                runtimes = {
                    {
                        name = "JavaSE-11",
                        path = home .. '/.sdkman/candidates/java/11.0.21-zulu'
                    },
                    {
                        name = "JavaSE-17",
                        path = home .. '/.sdkman/candidates/java/17.0.15-amzn'
                    }
                }
            }
        }
    },
    cmd = { 'jdtls', '--jvm-arg=-javaagent:' .. home .. '/.local/share/java/lombok.jar', '--jvm-arg=-Xmx4g' },
    on_attach = function(client, _)
        -- jdtls cannot resolve Scala-defined types from source in mixed projects.
        -- Downgrade "cannot be resolved" diagnostics to hints so Scala-import
        -- false positives don't clutter Trouble, while real Java errors (syntax
        -- errors, wrong signatures, etc.) still surface as errors/warnings.
        client.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
            if result and result.diagnostics then
                for _, d in ipairs(result.diagnostics) do
                    if d.message:find("cannot be resolved", 1, true) then
                        d.severity = 4 -- hint
                    end
                end
            end
            vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
        end
    end,
}
