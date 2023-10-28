local M = {}
local api = vim.api
local fn = vim.fn
local is_win32 = vim.fn.has 'win32' == 1 and true or false

M.formatter = {}

local default_config = function()
    return {
        buflisted = true,
        scratch = true,
        ft = 'REPL',
        wincmd = 'belowright 15 split',
        metas = {
            aichat = { cmd = 'aichat', formatter = M.formatter.bracketed_pasting },
            radian = { cmd = 'radian', formatter = M.formatter.bracketed_pasting_no_final_new_line },
            ipython = { cmd = 'ipython', formatter = M.formatter.bracketed_pasting },
            python = { cmd = 'python', formatter = M.formatter.trim_empty_lines },
            R = { cmd = 'R', formatter = M.formatter.trim_empty_lines },
            -- bash version >= 4.4 supports bracketed paste mode. but macos
            -- shipped with bash 3.2, so we don't use bracketed paste mode for
            -- bash.
            bash = { cmd = 'bash', formatter = M.formatter.trim_empty_lines },
            zsh = { cmd = 'zsh', formatter = M.formatter.bracketed_pasting },
        },
        close_on_exit = true,
        scroll_to_bottom_after_sending = true,
        os = {
            windows = {
                send_delayed_cr_after_sending = true,
            },
        },
    }
end

M._repls = {}
M._bufnrs_to_repls = {}

local function repl_is_valid(repl)
    return repl ~= nil and api.nvim_buf_is_loaded(repl.bufnr)
end

-- rearrange repls such that there's no gap in the repls table.
local function repl_cleanup()
    local valid_repls = {}
    local valid_repls_id = {}
    for id, repl in pairs(M._repls) do
        if repl_is_valid(repl) then
            table.insert(valid_repls_id, id)
        end
    end

    for bufnr, repl in pairs(M._bufnrs_to_repls) do
        if not repl_is_valid(repl) then
            M._bufnrs_to_repls[bufnr] = nil
        end

        if not api.nvim_buf_is_loaded(bufnr) then
            M._bufnrs_to_repls[bufnr] = nil
        end
    end

    table.sort(valid_repls_id)

    for _, id in ipairs(valid_repls_id) do
        table.insert(valid_repls, M._repls[id])
    end
    M._repls = valid_repls

    for id, repl in pairs(M._repls) do
        -- to avoid name conflict, we add a temp prefix
        api.nvim_buf_set_name(repl.bufnr, string.format('#%s#temp#%d', repl.name, id))
    end

    for id, repl in pairs(M._repls) do
        api.nvim_buf_set_name(repl.bufnr, string.format('#%s#%d', repl.name, id))
    end
end

local function focus_repl(repl)
    if not repl_is_valid(repl) then
        -- if id is nil, print it as -1
        vim.notify [[REPL doesn't exist!]]
        return
    end
    local win = fn.bufwinid(repl.bufnr)
    if win ~= -1 then
        api.nvim_set_current_win(win)
    else
        if type(M._config.wincmd) == 'function' then
            M._config.wincmd(repl.bufnr, repl.name)
        else
            vim.cmd(M._config.wincmd)
            api.nvim_set_current_buf(repl.bufnr)
        end
    end
end

local function create_repl(id, repl_name)
    if repl_is_valid(M._repls[id]) then
        vim.notify(string.format('REPL %d already exists, no new REPL is created', id))
        return
    end

    if not M._config.metas[repl_name] then
        vim.notify 'No REPL palatte is found'
        return
    end

    local bufnr = api.nvim_create_buf(M._config.buflisted, M._config.scratch)
    api.nvim_buf_set_option(bufnr, 'filetype', M._config.ft)

    local cmd

    if type(M._config.metas[repl_name].cmd) == 'function' then
        cmd = M._config.metas[repl_name].cmd()
    else
        cmd = M._config.metas[repl_name].cmd
    end

    if type(M._config.wincmd) == 'function' then
        M._config.wincmd(bufnr, repl_name)
    else
        vim.cmd(M._config.wincmd)
        api.nvim_set_current_buf(bufnr)
    end

    local opts = {}
    opts.on_exit = function()
        if M._config.close_on_exit then
            local bufwinid = fn.bufwinid(bufnr)
            while bufwinid ~= -1 do
                api.nvim_win_close(bufwinid, true)
                bufwinid = fn.bufwinid(bufnr)
            end
            -- It is possible that this buffer has already been deleted, before
            -- the process is exit.
            if api.nvim_buf_is_loaded(bufnr) then
                api.nvim_buf_delete(bufnr, { force = true })
            end
        end
        repl_cleanup()
    end

    local term = fn.termopen(cmd, opts)
    api.nvim_buf_set_name(bufnr, string.format('#%s#%d', repl_name, id))
    M._repls[id] = { bufnr = bufnr, term = term, name = repl_name }
end

-- get the id of the closest repl whose name is `NAME` from the `ID`
local function find_closest_repl_from_id_with_name(id, name)
    local closest_id = nil
    local closest_distance = math.huge
    for repl_id, repl in pairs(M._repls) do
        if repl.name == name then
            local distance = math.abs(repl_id - id)
            if distance < closest_distance then
                closest_id = repl_id
                closest_distance = distance
            end
            if distance == 0 then
                break
            end
        end
    end
    return closest_id
end

local function repl_swap(id_1, id_2)
    local repl_1 = M._repls[id_1]
    local repl_2 = M._repls[id_2]
    M._repls[id_1] = repl_2
    M._repls[id_2] = repl_1
    repl_cleanup()
end

local function attach_buffer_to_repl(bufnr, repl)
    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    if not api.nvim_buf_is_loaded(bufnr) then
        vim.notify [[Invalid buffer!]]
        return
    end
    M._bufnrs_to_repls[bufnr] = repl
end

M.bufnr_is_attached_to_repl = function(bufnr)
    if not repl_is_valid(M._bufnrs_to_repls[bufnr]) then
        return false
    else
        return true
    end
end

---@param id number|nil the id of the repl,
---@param name string|nil the name of the closest repl that will try to find
---@param bufnr number|nil the buffer number of the buffer
---@return table|nil repl the repl object or nil if not found
-- get the repl specified by `id` and `name`. If `id` is 0, then will try to
-- find the REPL `bufnr` is attached to, if not find, will use `id = 1`. If
-- `name` is not nil or not an empty string, then will try to find the REPL
-- with `name` relative to `id`.
function M._get_repl(id, name, bufnr)
    local repl
    if id == nil or id == 0 then
        repl = M._bufnrs_to_repls[bufnr]
        id = 1
        if not repl_is_valid(repl) then
            repl = M._repls[id]
        end
    else
        repl = M._repls[id]
    end

    if name ~= nil and name ~= '' then
        id = find_closest_repl_from_id_with_name(id, name)
        repl = M._repls[id]
    end

    if not repl_is_valid(repl) then
        return nil
    end

    return repl
end

local function repl_win_scroll_to_bottom(repl)
    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    local repl_win = fn.bufwinid(repl.bufnr)
    if repl_win ~= -1 then
        local lines = api.nvim_buf_line_count(repl.bufnr)
        api.nvim_win_set_cursor(repl_win, { lines, 0 })
    end
end

-- currently only support line-wise sending in both visual and operator mode.
local function get_lines(mode)
    local begin_mark = mode == 'operator' and "'[" or "'<"
    local end_mark = mode == 'operator' and "']" or "'>"

    local begin_line = fn.getpos(begin_mark)[2]
    local end_line = fn.getpos(end_mark)[2]
    return api.nvim_buf_get_lines(0, begin_line - 1, end_line, false)
end

function M.formatter.factory(opts)
    if type(opts) ~= 'table' then
        error 'opts must be a table'
    end

    local config = {
        replace_tab_by_space = false,
        number_of_spaces_to_replace_tab = 8,
        when_multi_lines = {
            open_code = '',
            end_code = '\r',
            trim_empty_lines = false,
            remove_leading_spaces = false,
            -- If gsub_pattern and gsub_repl are not empty, `string.gsub` will
            -- be called with `gsub_pattern` and `gsub_repl` on each line. Note
            -- that you should use Lua pattern instead of Vim regex pattern.
            -- The gsub calls happen after `trim_empty_lines`,
            -- `remove_leading_spaces`, and `replace_tab_by_space`, and before
            -- prepending and appending `open_code` and `end_code`.
            gsub_pattern = '',
            gsub_repl = '',
        },
        when_single_line = {
            open_code = '',
            end_code = '\r',
            gsub_pattern = '',
            gsub_repl = '',
        },
        os = {
            windows = {
                join_lines_with_cr = true,
            },
        },
    }

    config = vim.tbl_deep_extend('force', config, opts)

    return function(lines)
        if #lines == 1 then
            if config.replace_tab_by_space then
                lines[1] = lines[1]:gsub('\t', string.rep(' ', config.number_of_spaces_to_replace_tab))
            end

            lines[1] = lines[1]:gsub(config.when_single_line.gsub_pattern, config.when_single_line.gsub_repl)

            lines[1] = config.when_single_line.open_code .. lines[1] .. config.when_single_line.end_code
            return lines
        end

        local formatted_lines = {}
        local line = lines[1]

        line = line:gsub(config.when_multi_lines.gsub_pattern, config.when_multi_lines.gsub_repl)
        line = config.when_multi_lines.open_code .. line

        table.insert(formatted_lines, line)

        for i = 2, #lines do
            line = lines[i]

            if config.when_multi_lines.trim_empty_lines and line == '' then
                goto continue
            end

            if config.when_multi_lines.remove_leading_spaces then
                line = line:gsub('^%s+', '')
            end

            if config.replace_tab_by_space then
                line = line:gsub('\t', string.rep(' ', config.number_of_spaces_to_replace_tab))
            end

            line = line:gsub(config.when_multi_lines.gsub_pattern, config.when_multi_lines.gsub_repl)

            table.insert(formatted_lines, line)

            ::continue::
        end

        if config.when_multi_lines.end_code then
            table.insert(formatted_lines, config.when_multi_lines.end_code)
        end

        -- The `chansend` function joins lines with `\n`, which can result in a
        -- large number of unnecessary blank lines being sent to the REPL. For
        -- example, `{ "hello", "world", "again!" }` would be sent to the REPL
        -- as:

        -- ```
        -- hello
        --
        -- world
        --
        -- again!
        -- ```

        -- To prevent this issue, we manually join lines with `\r` on Windows.
        if is_win32 and config.os.windows.join_lines_with_cr then
            formatted_lines = { table.concat(formatted_lines, '\r') }
        end

        return formatted_lines
    end
end

M.formatter.trim_empty_lines = M.formatter.factory {
    when_multi_lines = {
        trim_empty_lines = true,
    },
}

M.formatter.bracketed_pasting = M.formatter.factory {
    when_multi_lines = {
        open_code = '\27[200~',
        end_code = '\27[201~\r',
    },
}

M.formatter.bracketed_pasting_no_final_new_line = M.formatter.factory {
    when_multi_lines = {
        open_code = '\27[200~',
        end_code = '\27[201~',
    },
}

M._send_motion_internal = function(motion)
    -- hack: allow dot-repeat
    if motion == nil then
        vim.go.operatorfunc = [[v:lua.require'yarepl'._send_motion_internal]]
        api.nvim_feedkeys('g@', 'ni', false)
    end

    local id = vim.b[0].repl_id
    local name = vim.b[0].closest_repl_name
    local current_bufnr = api.nvim_get_current_buf()

    local lines = get_lines 'operator'

    if #lines == 0 then
        vim.notify 'No motion!'
        return
    end

    M._send_strings(id, name, current_bufnr, lines)
end

M.setup = function(opts)
    M._config = vim.tbl_deep_extend('force', default_config(), opts or {})
end

api.nvim_create_user_command('REPLStart', function(opts)
    -- if calling the command without any count, we want count to become 1.
    local repl_name = opts.args
    local id = opts.count == 0 and 1 or opts.count
    local repl = M._repls[id]
    local current_bufnr = api.nvim_get_current_buf()

    if repl_is_valid(repl) then
        vim.notify(string.format('REPL %d already exists', id))
        focus_repl(repl)
        return
    end

    if repl_name == '' then
        local repls = {}
        for name, _ in pairs(M._config.metas) do
            table.insert(repls, name)
        end

        vim.ui.select(repls, {
            prompt = 'Select REPL: ',
        }, function(choice)
            repl_name = choice
            create_repl(id, repl_name)

            if opts.bang then
                attach_buffer_to_repl(current_bufnr, M._repls[id])
            end

            if M._config.scroll_to_bottom_after_sending then
                repl_win_scroll_to_bottom(M._repls[id])
            end
        end)
    else
        create_repl(id, repl_name)

        if opts.bang then
            attach_buffer_to_repl(current_bufnr, M._repls[id])
        end

        if M._config.scroll_to_bottom_after_sending then
            repl_win_scroll_to_bottom(M._repls[id])
        end
    end
end, {
    count = true,
    bang = true,
    nargs = '?',
    complete = function()
        local metas = {}
        for name, _ in pairs(M._config.metas) do
            table.insert(metas, name)
        end
        return metas
    end,
    desc = [[
Create REPL `i` from the list of available REPLs.
]],
})

---@param id number the id of the repl,
---@param name string|nil the name of the closest repl that will try to find
---@param bufnr number|nil the buffer number from which to find the attached REPL.
---@param strings table[string] a list of strings
---@param use_formatter boolean|nil whether use formatter (e.g. bracketed_pasting)? Default: true
-- Send a list of strings to the repl specified by `id` and `name` and `bufnr`.
-- If `id` is 0, then will try to find the REPL that `bufnr` is attached to, if
-- not find, will use `id = 1`. If `name` is not nil or not an empty string,
-- then will try to find the REPL with `name` relative to `id`. If `bufnr` is
-- nil or `bufnr` = 0, will find the REPL that current buffer is attached to.
M._send_strings = function(id, name, bufnr, strings, use_formatter)
    use_formatter = use_formatter == nil and true or use_formatter
    if bufnr == nil or bufnr == 0 then
        bufnr = api.nvim_get_current_buf()
    end

    local repl = M._get_repl(id, name, bufnr)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    if use_formatter then
        strings = M._config.metas[repl.name].formatter(strings)
    end

    fn.chansend(repl.term, strings)

    -- See https://github.com/milanglacier/yarepl.nvim/issues/12 and
    -- https://github.com/urbainvaes/vim-ripple/issues/12 for more information.
    -- It may be necessary to use a delayed `<CR>` on Windows to ensure that
    -- the code is executed in the REPL.
    if is_win32 and M._config.os.windows.send_delayed_cr_after_sending then
        vim.defer_fn(function()
            fn.chansend(repl.term, '\r')
        end, 100)
    end

    if M._config.scroll_to_bottom_after_sending then
        repl_win_scroll_to_bottom(repl)
    end
end

api.nvim_create_user_command(
    'REPLCleanup',
    repl_cleanup,
    { desc = 'clean invalid repls, and rearrange the repls order.' }
)

api.nvim_create_user_command('REPLFocus', function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local repl = M._get_repl(id, name, current_buffer)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    focus_repl(repl)
end, {
    count = true,
    nargs = '?',
    desc = [[
Focus on REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLHide', function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local repl = M._get_repl(id, name, current_buffer)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    local bufnr = repl.bufnr
    local win = fn.bufwinid(bufnr)
    while win ~= -1 do
        api.nvim_win_close(win, true)
        win = fn.bufwinid(bufnr)
    end
end, {
    count = true,
    nargs = '?',
    desc = [[
Hide REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLHideOrFocus', function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local repl = M._get_repl(id, name, current_buffer)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    local bufnr = repl.bufnr
    local win = fn.bufwinid(bufnr)
    if win ~= -1 then
        while win ~= -1 do
            api.nvim_win_close(win, true)
            win = fn.bufwinid(bufnr)
        end
    else
        focus_repl(repl)
    end
end, {
    count = true,
    nargs = '?',
    desc = [[
Hide or focus REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLClose', function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local repl = M._get_repl(id, name, current_buffer)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    fn.chansend(repl.term, string.char(4))
end, {
    count = true,
    nargs = '?',
    desc = [[
Close REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLSwap', function(opts)
    local id_1 = tonumber(opts.fargs[1])
    local id_2 = tonumber(opts.fargs[2])

    if id_1 ~= nil and id_2 ~= nil then
        repl_swap(id_1, id_2)
        return
    end

    local repl_ids = {}
    for id, _ in pairs(M._repls) do
        table.insert(repl_ids, id)
    end

    table.sort(repl_ids)

    if id_1 == nil then
        vim.ui.select(repl_ids, {
            prompt = 'select first REPL',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(id1)
            vim.ui.select(repl_ids, {
                prompt = 'select second REPL',
                format_item = function(item)
                    return item .. ' ' .. M._repls[item].name
                end,
            }, function(id2)
                repl_swap(id1, id2)
            end)
        end)
    elseif id_2 == nil then
        vim.ui.select(repl_ids, {
            prompt = 'select second REPL',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(id2)
            repl_swap(id_1, id2)
        end)
    end
end, {
    desc = [[Swap two REPLs]],
    nargs = '*',
})

api.nvim_create_user_command('REPLAttachBufferToREPL', function(opts)
    local current_buffer = api.nvim_get_current_buf()

    if opts.bang then
        M._bufnrs_to_repls[current_buffer] = nil
        return
    end

    local repl_id = opts.count

    local repl_ids = {}
    for id, _ in pairs(M._repls) do
        table.insert(repl_ids, id)
    end

    -- count = 0 means no count is provided
    if repl_id == 0 then
        vim.ui.select(repl_ids, {
            prompt = 'select REPL that you want to attach to',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(id)
            attach_buffer_to_repl(current_buffer, M._repls[id])
        end)
    else
        attach_buffer_to_repl(current_buffer, M._repls[repl_id])
    end
end, {
    count = true,
    bang = true,
    desc = [[
Attach current buffer to REPL `i`
]],
})

api.nvim_create_user_command('REPLDetachBufferToREPL', function()
    local current_buffer = api.nvim_get_current_buf()
    M._bufnrs_to_repls[current_buffer] = nil
end, {
    count = true,
    desc = [[Detach current buffer to any REPL.]],
})

api.nvim_create_user_command('REPLSendVisual', function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    -- we must use `<ESC>` to clear those marks to mark '> and '> to be able to
    -- access the updated visual range. Those magic letters 'nx' are coming
    -- from Vigemus/iron.nvim and I am not quiet understand the effect of those
    -- magic letters.
    api.nvim_feedkeys('\27', 'nx', false)

    local lines = get_lines 'visual'

    if #lines == 0 then
        vim.notify 'No visual range!'
        return
    end

    M._send_strings(id, name, current_buffer, lines)
end, {
    count = true,
    nargs = '?',
    desc = [[
Send visual range to REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLSendLine', function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local line = api.nvim_get_current_line()

    M._send_strings(id, name, current_buffer, { line })
end, {
    count = true,
    nargs = '?',
    desc = [[
Send current line to REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLSendMotion', function(opts)
    local repl_name = opts.args
    local id = opts.count

    if repl_name ~= '' then
        vim.b[0].closest_repl_name = repl_name
    else
        vim.b[0].closest_repl_name = nil
    end

    if id ~= 0 then
        vim.b[0].repl_id = id
    else
        vim.b[0].repl_id = nil
    end

    vim.go.operatorfunc = [[v:lua.require'yarepl'._send_motion_internal]]
    -- Those magic letters 'ni' are coming from Vigemus/iron.nvim and I am not
    -- quite understand the effect of those magic letters.
    api.nvim_feedkeys('g@', 'ni', false)
end, {
    count = true,
    nargs = '?',
    desc = [[
Send motion to REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLExec', function(opts)
    local first_arg = opts.fargs[1]
    local current_buffer = api.nvim_get_current_buf()
    local name = ''
    local command = opts.args

    for repl_name, _ in pairs(M._config.metas) do
        if '$' .. repl_name == first_arg then
            name = first_arg:sub(2)
            break
        end
    end

    if name ~= '' then
        command = command:gsub('^%$' .. name .. '%s+', '')
    end

    local id = opts.count
    local command_list = vim.split(command, '\r')

    M._send_strings(id, name, current_buffer, command_list)
end, {
    count = true,
    nargs = '*',
    desc = [[
Execute a command in REPL `i` or the REPL that current buffer is attached to.
]],
})

return M
