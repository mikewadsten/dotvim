vim.o.updatetime = 250
-- Show diagnostic info in a floating window when cursor is sitting
vim.diagnostic.config({
    virtual_text = false,
})

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
    vim.lsp.handlers.hover, {
        border = 'rounded',
    }
)

local opts = { noremap=true, silent=true }

-- <C-q> calls hover() - basically acts like C-q does in PyCharm.
vim.api.nvim_set_keymap(
    'n', '<C-q>', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
-- <Leader>ln goes to next diagnostic, <Leader>lp goes to previous
-- (I initially used <Leader>ldn but that's too close to my <Leader>d!)
vim.api.nvim_set_keymap(
    'n', '<Leader>ln', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
vim.api.nvim_set_keymap(
    'n', '<Leader>lp', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
vim.api.nvim_set_keymap(
    'n', '<Leader>ll', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
-- gd, gi and gr go to definition, implementation, and references
local gmappings = {
    d = { name = 'definition', help = 'Press Ctrl-O to jump back' },
    -- implementation() is not implemented on pylsp, boo
    -- i = { name = 'implementation', help = 'Press Ctrl-O to jump back' },
    r = { name = 'references' },
}
for key, fn in pairs(gmappings) do
    vim.api.nvim_set_keymap(
        'n', 'g' .. key, '', {
        callback = function()
            vim.lsp.buf[fn.name]()
            -- I haven't used jumplist stuff for a long time;
            -- I need a reminder of how it works.
            if fn.help ~= nil then
                print(fn.help)
            end
        end,
        noremap = true, silent = true,
    })
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

vim.api.nvim_set_keymap('n', '<Leader>l?', '', {
    noremap = true, silent = true,
    callback = lsphelp
})
-- Helpful fallback mapping - <Leader>l (with no other keys) displays
-- the same help message once the mapping times out.
vim.api.nvim_set_keymap(
    'n', '<Leader>l', '',
    {callback=lsphelp, noremap=true, silent=true})

-- solarized colorscheme defaults floating window to reversed colors, which, ew
-- Then here we define FloatBorder so that it's just a round gray line
vim.cmd('highlight NormalFloat cterm=NONE')
vim.cmd('highlight FloatBorder ctermfg=245')

vim.cmd('highlight! DiagnosticFloatingWarn ctermfg=3 ctermbg=235 cterm=NONE guifg=Orange')
vim.cmd('highlight! link DiagnosticError DiagnosticWarn')
vim.cmd('highlight DiagnosticUnderlineWarn'
        .. ' ctermbg=yellow ctermfg=16 cterm=bold'
        .. ' guibg=Orange   guifg=Black gui=bold')
local diagsigns = {
    Warn = {
        icon = "\u{1f4d0}",  -- Triangular Ruler
        fg = { term = 3, gui = 'Orange' },
    },
    Error = {
        icon = "\u{26d4}",  -- No Entry
        fg = { term = 1, gui = 'Red' },
    },
}
for type, sign in pairs(diagsigns) do
    local hl = "DiagnosticSign" .. type
    vim.cmd(
        'highlight Diagnostic' .. type
        .. ' ctermbg=235 guibg=#073642 cterm=bold,standout gui=bold,standout'
        .. ' ctermfg=' .. sign.fg.term .. ' guifg=' .. sign.fg.gui )
    vim.fn.sign_define(hl, { text = sign.icon, texthl = hl, numhl = hl })
end

local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    -- Set SuperTab to prefer omnifunc over autocompletion
    vim.b[bufnr].SuperTabContextTextOmniPrecedence = {'&omnifunc', '&completefunc'}
    vim.b[bufnr].SuperTabDefaultCompletionType = "context"

    vim.api.nvim_create_autocmd("CursorHold", {
        buffer = bufnr,
        callback = function()
            local opts = {
                focusable = false,
                close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                border = 'rounded',
                source = 'always',
                prefix = ' ',
                scope = 'line',
            }
            vim.diagnostic.open_float(nil, opts)
        end
    })

    local lsp_sig_available, sig = pcall(require, 'lsp_signature')
    if lsp_sig_available then
        sig.on_attach({
            -- doc_lines = 3,
            handler_opts = {
                border = "rounded"
            },
            -- Don't do virtual text to show the current parameter's name
            hint_enable = false,
            -- C-q toggles off the signature window while in Insert mode
            toggle_key = '<C-q>',
        })
    end
end

local function pylsp_on_init(client)
    if vim.fn.filereadable(client.config.cmd_cwd .. '/nose2.cfg') == 1 then
        -- The only project I work on where nose2 is used is Python 2-based.
        -- python-lsp-server (pylsp) is Python 3.7+, so its use of pyflakes
        -- is also Python 3, which makes it barf at things like `print abc`.
        -- So... just disable pyflakes when working on such projects.
        client.config.settings.pylsp = {
            plugins = {
                pyflakes = { enabled = false }
            }
        }
        client.notify("workspace/didChangeConfiguration")
    end
    return true
end

local function setup_lsp(lsp_)
    local servers = {
        pylsp = {
            on_init = pylsp_on_init,
        },
        clangd = {
            -- TODO
            on_init = nil,
        }
    }
    for server, cfg in pairs(servers) do
        if vim.fn.executable(server) == 1 then
            lsp_[server].setup {
                on_init = cfg.on_init,
                on_attach = on_attach,
            }
        end
    end
end

local function setup_barbecue(bbq)
    bbq.setup({
        symbols = {
            -- I don't necessary have fancy fonts installed
            separator = ">",
        },
        -- Again, I don't necessarily have fancy fonts with symbols installed
        kinds = false,
        -- Right now I only have LSP working for Python, so let's not show
        -- the winbar for C or C++ files.
        -- If we had a way to make this include_filetypes, we'd make it only
        -- Python...
        exclude_filetypes = {"c", "cpp", "text"},
        theme = {
            normal = { bg = "#000000" },
        },
    })
end

if vim.fn.has('nvim-0.8') then
    local barbecue_available, bbq = pcall(require, 'barbecue')
    if barbecue_available then
        setup_barbecue(bbq)
    else
        vim.fn.timer_start(50, function()
            vim.cmd([[PlugInstall]])
            setup_barbecue(require('barbecue'))
        end)
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
