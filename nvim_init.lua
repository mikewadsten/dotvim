if vim.fn.executable('pylsp') then
    local function setup_lsp_servers(lsp_)
        lsp_.pylsp.setup{}
    end

    local lsp_plugin_available, lsp = pcall(require, 'lspconfig')
    if lsp_plugin_available then
        setup_lsp_servers(lsp)
    else
        print("lspconfig not found? Let's run PlugInstall...")
        vim.fn.timer_start(50, function()
            vim.cmd([[PlugInstall]])
            setup_lsp_servers(require('lspconfig'))
        end)
    end
end
