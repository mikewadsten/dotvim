local opts = { noremap=true, silent=true }
local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    -- Set SuperTab to prefer omnifunc over autocompletion
    vim.b[bufnr].SuperTabContextTextOmniPrecedence = {'&omnifunc', '&completefunc'}
    vim.b[bufnr].SuperTabDefaultCompletionType = "context"

    vim.o.updatetime = 250
    -- Show diagnostic info in a floating window when cursor is sitting
    vim.diagnostic.config({
        virtual_text = false
    })
    vim.api.nvim_create_autocmd("CursorHold", {
        buffer = bufnr,
        callback = function()
            local opts = {
                focusable = false,
                close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                -- TODO how to make it actually rounded? Font maybe?
                border = 'rounded',
                source = 'always',
                prefix = ' ',
                scope = 'line',
            }
            vim.diagnostic.open_float(nil, opts)
        end
    })

    -- TODO mappings
    -- <C-q> calls hover() - basically acts like C-q does in PyCharm.
    vim.api.nvim_buf_set_keymap(
        bufnr, 'n', '<C-q>', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    -- <Leader>ln goes to next diagnostic, <Leader>lp goes to previous
    -- (I initially used <Leader>ldn but that's too close to my <Leader>d!)
    vim.api.nvim_buf_set_keymap(
        bufnr, 'n', '<Leader>ln', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
    vim.api.nvim_buf_set_keymap(
        bufnr, 'n', '<Leader>lp', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
    vim.api.nvim_buf_set_keymap(
        bufnr, 'n', '<Leader>ll', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
    -- gd, gi and gr go to definition, implementation, and references
    local gmappings = {
        d = { name = 'definition', help = 'Press Ctrl-O to jump back' },
        -- implementation() is not implemented on pylsp, boo
        -- i = { name = 'implementation', help = 'Press Ctrl-O to jump back' },
        r = { name = 'references' },
    }
    for key, fn in pairs(gmappings) do
        vim.api.nvim_buf_set_keymap(
            bufnr, 'n', 'g' .. key, '', {
                callback = function()
                    vim.lsp.buf[fn.name]()
                    -- I haven't used jumplist stuff for a long time;
                    -- I need a reminder of how it works.
                    if fn.help ~= nil then
                        print(fn.help)
                    end
                end,
                noremap = true, silent = true,
            }
        )
    end
    local function lsphelp()
        local chunks = {
            {'<Leader>ln and <Leader>lp => go to next/prev diagnostic\n'},
            {'<Leader>ll opens loclist (diagnostic list)\n'},
        }
        for key, fn in pairs(gmappings) do
            table.insert(chunks, { 'g' .. key .. ' => go to ' .. fn.name .. '\n' })
        end
        table.insert(chunks, {'<Leader>l? opens this help'})
        vim.api.nvim_echo(chunks, false, {})
    end

    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Leader>l?', '', {
        noremap = true, silent = true,
        callback = lsphelp
    })
    -- Helpful fallback mapping - <Leader>l (with no other keys) displays
    -- the same help message once the mapping times out.
    vim.api.nvim_buf_set_keymap(
        bufnr, 'n', '<Leader>l', '',
        {callback=lsphelp, noremap=true, silent=true})

    local lsp_sig_available, sig = pcall(require, 'lsp_signature')
    if lsp_sig_available then
        sig.on_attach()
    end
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
