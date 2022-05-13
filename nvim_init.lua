if vim.fn.executable('pylsp') then
    require('lspconfig').pylsp.setup{}
end
