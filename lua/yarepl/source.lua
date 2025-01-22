local M = {
    ft = {},
    meta = {},
}

-- @param filename string: Path to the file to execute
-- @return string: Python code that will execute the file's contents
M.ft.python = function(filename)
    return string.format("exec(open('%s').read())", filename)
end

--- Generate bash/zsh code to source a file in the REPL
-- @param filename string: Path to the file to source
-- @return string: Shell command that will source the file
M.ft.sh = function(filename)
    return string.format("source '%s'", filename)
end

--- Generate R code to source a file in the REPL
-- @param filename string: Path to the file to source
-- @return string: R code that will source the file
M.ft.r = function(filename)
    return string.format("source('%s')", filename)
end

--- Register a filetype handler for sourcing files
-- @param ft string: Filetype to register (e.g. 'python')
-- @param fn function: Function that takes a filename and returns code to execute it
M.register_ft = function(ft, fn)
    M.ft[ft] = fn
end

--- Register a metadata type that maps to a filetype
-- @param meta string: Metadata type identifier
-- @param ft string: Filetype to map to
M.register_meta = function(meta, ft)
    M.meta[meta] = ft
end

M.register_meta('ipython', 'python')
M.register_meta('python', 'python')
M.register_meta('bash', 'sh')
M.register_meta('zsh', 'sh')
M.register_meta('radian', 'r')
M.register_meta('R', 'r')

return M
