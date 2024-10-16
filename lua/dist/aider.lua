local keymap = vim.api.nvim_set_keymap

local M = {}

M.wincmd = function(bufnr)
    vim.cmd 'tabedit'
    vim.api.nvim_set_current_buf(bufnr)
    vim.cmd 'setlocal signcolumn=no'
    vim.cmd 'startinsert'
end

-- Predefined prefix setters
local prefixes = {
    '',
    '/add',
    '/architect',
    '/ask',
    '/chat-mode',
    '/clear',
    '/code',
    '/commit',
    '/copy',
    '/diff',
    '/drop',
    '/exit',
    '/git',
    '/help',
    '/lint',
    '/ls',
    '/map',
    '/map-refresh',
    '/model',
    '/models',
    '/paste',
    '/quit',
    '/read-only',
    '/report',
    '/reset',
    '/run',
    '/settings',
    '/test',
    '/tokens',
    '/undo',
    '/voice',
    '/web',
}

local aider_args = {
    '--model',
    '--opus',
    '--sonnet',
    '--4',
    '--4o',
    '--mini',
    '--4-turbo',
    '--35turbo',
    '--deepseek',
    '--o1-mini',
    '--o1-preview',
    '--architect',
    '--weak-model',
    '--editor-model',
    '--editor-edit-format',
    '--show-model-warnings',
    '--no-show-model-warnings',
    '--cache-prompts',
    '--no-cache-prompts',
    '--map-refresh',
    '--map-multiplier-no-files',
    '--restore-chat-history',
    '--no-restore-chat-history',
    '--pretty',
    '--no-pretty',
    '--stream',
    '--no-stream',
    '--user-input-color',
    '--tool-output-color',
    '--tool-error-color',
    '--tool-warning-color',
    '--assistant-output-color',
    '--completion-menu-color',
    '--completion-menu-bg-color',
    '--completion-menu-current-color',
    '--completion-menu-current-bg-color',
    '--code-theme',
    '--show-diffs',
    '--git',
    '--no-git',
    '--gitignore',
    '--no-gitignore',
    '--aiderignore',
    '--subtree-only',
    '--auto-commits',
    '--no-auto-commits',
    '--dirty-commits',
    '--no-dirty-commits',
    '--attribute-author',
    '--no-attribute-author',
    '--attribute-committer',
    '--no-attribute-committer',
    '--attribute-commit-message-author',
    '--no-attribute-commit-message-author',
    '--attribute-commit-message-committer',
    '--no-attribute-commit-message-committer',
    '--commit',
    '--commit-prompt',
    '--dry-run',
    '--no-dry-run',
    '--skip-sanity-check-repo',
    '--lint',
    '--lint-cmd',
    '--auto-lint',
    '--no-auto-lint',
    '--test-cmd',
    '--auto-test',
    '--no-auto-test',
    '--test',
    '--file',
    '--read',
    '--vim',
    '--chat-language',
    '--install-main-branch',
    '--apply',
    '--yes-always',
    '-v',
    '--show-repo-map',
    '--show-prompts',
    '--message',
    '--message-file',
    '--encoding',
    '-c',
    '--gui',
    '--suggest-shell-commands',
    '--no-suggest-shell-commands',
    '--voice-format',
    '--voice-language',
}

-- Create a closure for prefix handling
local function create_prefix_handler()
    local yarepl = require 'yarepl'
    local current_prefix = ''

    local add_prefix = function(strings)
        if #current_prefix > 0 and #strings > 0 then
            strings[1] = current_prefix .. ' ' .. strings[1]
        end

        return yarepl.formatter.bracketed_pasting(strings)
    end

    return {
        set_prefix = function(prefix)
            if not vim.tbl_contains(prefixes, prefix) then
                vim.notify('Unknown prefix for aider: ' .. prefix, vim.log.levels.WARN)
                return
            end
            current_prefix = prefix
        end,
        formatter = add_prefix,
    }
end

-- Initialize the prefix handler
local prefix_handler = create_prefix_handler()

-- Expose the sender function
M.formatter = prefix_handler.formatter
M.set_prefix = prefix_handler.set_prefix
M.aider_args = {}
M.aider_cmd = 'aider'

M.setup = function(params)
    M.aider_cmd = params.aider_cmd or M.aider_cmd
    M.aider_args = params.aider_args or M.aider_args
    M.wincmd = params.wincmd or M.wincmd
end

M.create_aider_meta = function()
    return {
        cmd = function()
            local args
            -- build up the command to launch aider based on M.aider_args (the
            -- command line options) and the M.aider_cmd.
            if type(M.aider_cmd) == 'string' then
                args = vim.deepcopy(M.aider_args)
                table.insert(args, 1, M.aider_cmd)
            elseif type(M.aider_cmd == 'table') then
                args = vim.deepcopy(M.aider_cmd)
                for _, arg in ipairs(M.aider_args) do
                    table.insert(args, arg)
                end
            else
                vim.notify('invalid aider cmd type', vim.log.levels.ERROR)
                return
            end

            return args
        end,
        formatter = M.formatter,
        wincmd = M.wincmd,
    }
end

function M.send_to_aider_no_format(id, lines)
    local yarepl = require 'yarepl'
    local bufnr = vim.api.nvim_get_current_buf()
    yarepl._send_strings(id, 'aider', bufnr, lines, false)
end

vim.api.nvim_create_user_command('AiderArgs', function(opts)
    M.aider_args = opts.fargs or {}
end, {
    nargs = '*',
    complete = function()
        return aider_args
    end,
})

vim.api.nvim_create_user_command('AiderSetPrefix', function(opts)
    local prefix = opts.args

    if prefix == '' then
        vim.ui.select(prefixes, {
            prompt = 'Select prefix: ',
        }, function(choice)
            if not choice then
                return
            end

            M.set_prefix(choice)
        end)
    else
        M.set_prefix(prefix)
    end
end, {
    nargs = '?',
    complete = function()
        return prefixes
    end,
})

vim.api.nvim_create_user_command('AiderRemovePrefix', function()
    M.set_prefix ''
end, {})

local shortcuts = {
    { name = 'Yes', key = 'y' },
    { name = 'No', key = 'n' },
    { name = 'Abort', key = '\3' }, -- Ctrl-c
    { name = 'Exit', key = '\4' }, -- Ctrl-d
    { name = 'Diff', key = '/diff' },
    { name = 'Paste', key = '/paste' },
    { name = 'Clear', key = '/clear' },
    { name = 'Undo', key = '/undo' },
    { name = 'Reset', key = '/reset' },
    { name = 'Drop', key = '/drop' },
    { name = 'Ls', key = '/ls' },
}

local function run_cmd_with_count(cmd)
    vim.cmd(string.format('%d%s', vim.v.count, cmd))
end

local function partial_cmd_with_count_expr(cmd)
    -- <C-U> is equivalent to \21, we want to clear the range before
    -- next input to ensure the count is recognized correctly.
    return ':\21' .. vim.v.count .. cmd
end

for _, shortcut in ipairs(shortcuts) do
    vim.api.nvim_create_user_command('AiderSend' .. shortcut.name, function(opts)
        local id = opts.count
        M.send_to_aider_no_format(id, { shortcut.key .. '\r' })
    end, { count = true })

    keymap('n', string.format('<Plug>(AiderSend%s)', shortcut.name), '', {
        noremap = true,
        callback = function()
            run_cmd_with_count('AiderSend' .. shortcut.name)
        end,
    })
end

vim.api.nvim_create_user_command('AiderExec', function(opts)
    local id = opts.count
    local command = opts.args
    M.send_to_aider_no_format(id, command .. '\r')
end, {
    count = true,
    nargs = '*',
    complete = function()
        return prefixes
    end,
})

keymap('n', '<Plug>(AiderExec)', '', {
    noremap = true,
    callback = function()
        return partial_cmd_with_count_expr 'AiderExec'
    end,
    expr = true,
})

-- general keymap from yarepl
keymap('n', '<Leader>as', '<Plug>(REPLStart-aider)', {
    desc = 'Start an aider REPL',
})
keymap('n', '<Leader>af', '<Plug>(REPLFocus-aider)', {
    desc = 'Focus on aider REPL',
})
keymap('n', '<Leader>ah', '<Plug>(REPLHide-aider)', {
    desc = 'Hide aider REPL',
})
keymap('v', '<Leader>ar', '<Plug>(REPLSendVisual-aider)', {
    desc = 'Send visual region to aider',
})
keymap('n', '<Leader>arr', '<Plug>(REPLSendLine-aider)', {
    desc = 'Send lines to aider',
})
keymap('n', '<Leader>ar', '<Plug>(REPLSendOperator-aider)', {
    desc = 'Send Operator to aider',
})

-- special keymap from aider
keymap('n', '<Leader>ae', '<Plug>(AiderExec)', {
    desc = 'Execute command in aider',
})
keymap('n', '<Leader>ay', '<Plug>(AiderSendYes)', {
    desc = 'Send y to aider',
})
keymap('n', '<Leader>an', '<Plug>(AiderSendNo)', {
    desc = 'Send n to aider',
})
keymap('n', '<Leader>aa', '<Plug>(AiderSendAbort)', {
    desc = 'Send abort to aider',
})
keymap('n', '<Leader>aq', '<Plug>(AiderSendExit)', {
    desc = 'Send exit to aider',
})
keymap('n', '<Leader>ag', '<cmd>AiderSetPrefix<cr>', {
    desc = 'set aider prefix',
})
keymap('n', '<Leader>aG', '<cmd>AiderRemovePrefix<cr>', {
    desc = 'remove aider prefix',
})
keymap('n', '<Leader>a<space>', '<cmd>checktime<cr>', {
    desc = 'sync file changes by aider to nvim buffer',
})

return M
