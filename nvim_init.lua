local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    -- Set SuperTab to prefer omnifunc over autocompletion
    vim.b[bufnr].SuperTabContextTextOmniPrecedence = {'&omnifunc', '&completefunc'}
    vim.b[bufnr].SuperTabDefaultCompletionType = "context"

    -- TODO mappings
end

local function setup_lsp(lsp_)
    if vim.fn.executable('pylsp') then
        lsp_.pylsp.setup{
            on_attach = on_attach,
        }
    end
end

local lsp_plugin_available, lsp = pcall(require, 'lspconfig')
if lsp_plugin_available then
    setup_lsp(lsp)
else
    print("lspconfig not found? Let's run PlugInstall...")
    vim.fn.timer_start(50, function()
        vim.cmd([[PlugInstall]])
        setup_lsp(require('lspconfig'))
    end)
end
