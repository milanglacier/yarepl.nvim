local keymap = vim.api.nvim_set_keymap
local util = require 'yarepl.extensions.utility'

local M = {}
M.show_winbar_in_float_window = true

M.wincmd = function(bufnr, name)
    local winid = vim.api.nvim_open_win(bufnr, true, {
        relative = 'laststatus',
        row = 0,
        col = math.floor(vim.o.columns * 0.5),
        width = math.floor(vim.o.columns * 0.5),
        height = math.floor(vim.o.lines * 0.7),
        style = 'minimal',
        title = name,
        border = 'rounded',
        title_pos = 'center',
    })
    if M.show_winbar_in_float_window then
        vim.wo[winid].winbar = '%t'
    end
end

local opencode_args = {
    '--continue',
    '--session',
    '--fork',
    '--prompt',
    '--agent',
    '--model',
    '--pure',
    '--print-logs',
    '--log-level',
    '--port',
    '--hostname',
    '--mdns',
    '--mdns-domain',
    '--cors',
    '--help',
}

local slash_commands = {
    '/clear',
    '/compact',
    '/connect',
    '/continue',
    '/editor',
    '/exit',
    '/export',
    '/help',
    '/init',
    '/models',
    '/new',
    '/q',
    '/quit',
    '/redo',
    '/resume',
    '/sessions',
    '/share',
    '/summarize',
    '/themes',
    '/thinking',
    '/undo',
    '/unshare',
}

M.formatter = 'bracketed_pasting'
M.opencode_args = {}
M.opencode_cmd = 'opencode'

M.setup = function(params)
    M = vim.tbl_deep_extend('force', M, params or {})
end

M.create_opencode_meta = function()
    return {
        cmd = function()
            local args
            if type(M.opencode_cmd) == 'string' then
                args = vim.deepcopy(M.opencode_args)
                table.insert(args, 1, M.opencode_cmd)
            elseif type(M.opencode_cmd) == 'table' then
                args = vim.deepcopy(M.opencode_cmd)
                for _, arg in ipairs(M.opencode_args) do
                    table.insert(args, arg)
                end
            else
                vim.notify('invalid opencode cmd type', vim.log.levels.ERROR)
                return
            end

            return args
        end,
        formatter = M.formatter,
        wincmd = M.wincmd,
    }
end

local shortcuts = {
    { name = 'send_compact', key = '/compact', requires_cr = true },
    { name = 'send_connect', key = '/connect', requires_cr = true },
    { name = 'send_open_editor', key = '\24e', requires_cr = false },
    { name = 'send_exit', key = '/exit', requires_cr = true },
    { name = 'send_export', key = '/export', requires_cr = true },
    { name = 'send_help', key = '/help', requires_cr = true },
    { name = 'send_init', key = '/init', requires_cr = true },
    { name = 'send_models', key = '/models', requires_cr = true },
    { name = 'send_new', key = '/new', requires_cr = true },
    { name = 'send_redo', key = '/redo', requires_cr = true },
    { name = 'send_sessions', key = '/sessions', requires_cr = true },
    { name = 'send_share', key = '/share', requires_cr = true },
    { name = 'send_thinking', key = '/thinking', requires_cr = true },
    { name = 'send_undo', key = '/undo', requires_cr = true },
    { name = 'send_unshare', key = '/unshare', requires_cr = true },
    { name = 'send_scroll_up', key = '\27\21', requires_cr = false },
    { name = 'send_scroll_down', key = '\27\4', requires_cr = false },
}

local opencode_commands = {}
local opencode_completions = {}

for _, shortcut in ipairs(shortcuts) do
    opencode_commands[shortcut.name] = function(opts)
        local id = opts.count
        util.send_to_repl_raw('opencode', id, shortcut.key, shortcut.requires_cr)
    end
    opencode_completions[shortcut.name] = true
end

opencode_commands.exec = function(opts)
    local id = opts.count
    local command = opts.args
    util.send_to_repl_raw('opencode', id, command, true)
end

opencode_completions.exec = function()
    return slash_commands
end

opencode_commands.set_args = function(opts)
    M.opencode_args = opts.fargs or {}
end

opencode_completions.set_args = function()
    return opencode_args
end

local yarepl = require 'yarepl'

yarepl.commands.opencode = function(opts)
    local fargs = opts.fargs
    if #fargs == 0 then
        vim.notify('Yarepl opencode: subcommand required', vim.log.levels.ERROR)
        return
    end

    local subcmd = table.remove(fargs, 1)
    local handler = opencode_commands[subcmd]
    if not handler then
        vim.notify('Yarepl opencode: unknown subcommand: ' .. subcmd, vim.log.levels.ERROR)
        return
    end

    handler { args = table.concat(fargs, ' '), fargs = fargs, count = opts.count, bang = opts.bang }
end

yarepl.completions.opencode = opencode_completions

for _, shortcut in ipairs(shortcuts) do
    local plug_name = shortcut.name:gsub('_', '-')
    keymap('n', '<Plug>(yarepl-opencode-' .. plug_name .. ')', '', {
        noremap = true,
        callback = function()
            util.run_cmd_with_count('Yarepl opencode ' .. shortcut.name)
        end,
    })
end

keymap('n', '<Plug>(yarepl-opencode-exec)', '', {
    noremap = true,
    callback = function()
        return util.partial_cmd_with_count_expr 'Yarepl opencode exec '
    end,
    expr = true,
})

return M
