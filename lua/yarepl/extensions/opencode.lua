local keymap = vim.api.nvim_set_keymap
local util = require 'yarepl.extensions.utility'

local M = {}

local function default_wincmd(bufnr, name)
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
    if M.config.show_winbar_in_float_window then
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

---@class yarepl.extensions.OpencodeConfig
---@field show_winbar_in_float_window boolean
---@field wincmd fun(bufnr: number, name: string)
---@field formatter string
---@field opencode_args string[]
---@field opencode_cmd string|string[]
---@field warn_on_EDITOR_env_var boolean
---@type yarepl.extensions.OpencodeConfig
M.config = {
    show_winbar_in_float_window = true,
    wincmd = default_wincmd,
    formatter = 'bracketed_pasting_delayed_cr',
    opencode_args = {},
    opencode_cmd = 'opencode',
    warn_on_EDITOR_env_var = true,
}

M.setup = function(params)
    M.config = vim.tbl_deep_extend('force', M.config, params or {})
end

M.create_opencode_meta = function()
    return {
        cmd = function()
            ---@type string[]
            local args
            local cmd = M.config.opencode_cmd
            if type(cmd) == 'string' then
                args = vim.deepcopy(M.config.opencode_args)
                table.insert(args, 1, cmd)
            elseif type(cmd) == 'table' then
                ---@type string[]
                local cmd_args = cmd
                args = vim.deepcopy(cmd_args)
                for _, arg in ipairs(M.config.opencode_args) do
                    table.insert(args, arg)
                end
            else
                vim.notify('invalid opencode cmd type', vim.log.levels.ERROR)
                return
            end

            return args
        end,
        formatter = M.config.formatter,
        wincmd = M.config.wincmd,
        send_delayed_final_cr = true,
    }
end

local shortcuts = {
    { name = 'send_compact', key = '/compact', requires_cr = true },
    { name = 'send_connect', key = '/connect', requires_cr = true },
    {
        name = 'send_open_editor',
        key = '\24e',
        requires_cr = false,
        pre_hook = function()
            if M.config.warn_on_EDITOR_env_var and ((not vim.env.EDITOR) or (not vim.env.EDITOR:find 'nvr')) then
                vim.notify('current $EDITOR command is not nvr, please consider using nvr', vim.log.levels.WARN)
            end
        end,
    },
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
        if type(shortcut.pre_hook) == 'function' then
            shortcut.pre_hook()
        end
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
    M.config.opencode_args = opts.fargs or {}
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
