local fzf = require 'fzf-lua'
local builtin = require 'fzf-lua.previewer.builtin'

local Previewer = builtin.buffer_or_file:extend()

function Previewer:new(o, opts, fzf_win)
    Previewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, Previewer)
    return self
end

local function get_buf_name_without_dir(bufnr)
    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
end

function Previewer:parse_entry(entry_str)
    local repls = require('yarepl')._repls

    for _, repl in ipairs(repls) do
        if get_buf_name_without_dir(repl.bufnr) == entry_str then
            return { bufnr = repl.bufnr, path = entry_str }
        end
    end

    return { path = entry_str }
end

local repl_show = function(opts)
    local repls = require('yarepl')._repls
    local buffers = {}
    for _, repl in ipairs(repls) do
        table.insert(buffers, get_buf_name_without_dir(repl.bufnr))
    end
    if #buffers == 0 then
        return
    end

    local default_opts = {}
    default_opts.previewer = Previewer
    default_opts.actions = {
        ['default'] = function(e)
            local entry_str = e[1]

            for id, repl in ipairs(repls) do
                if get_buf_name_without_dir(repl.bufnr) == entry_str then
                    -- the default action is to open the REPL buffer with configured wincmd
                    vim.cmd(id .. 'REPLFocus')
                    return
                end
            end
        end,
    }

    opts = vim.tbl_deep_extend('force', default_opts, opts or {})

    fzf.fzf_exec(buffers, opts)
end

local M = { repl_show = repl_show }

return M
