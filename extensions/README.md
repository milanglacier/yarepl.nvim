# Aider

## Overview

This is an auxiliary functionality for
yarepl designed to enhance
the integration with the [aider](https://github.com/paul-gauthier/aider) AI
coding assistant. It provides a set of commands and keymaps to streamline the
interaction between Neovim and aider, making it easier to use AI-assisted
coding within your editor.

## Features

- Seamless integration with yarepl.nvim for aider sessions
- Custom prefix handling for aider commands
- Predefined shortcuts for common aider actions
- Configurable aider arguments

## Commands

The `yarepl.extensions.aider` module offers command-line completions to help
you configure Aider as needed.

- `AiderSetPrefix`: Specify a `/` prefix for Aider commands, such as `/ask`,
  `/architect`, etc. When sending buffer content to the Aider REPL, the specified
  prefix will be prepended to the buffer content.
- `AiderRemovePrefix`: Remove the current prefix
- `AiderSend<Action>`: Send specific actions to aider (e.g., `:AiderSendYes`,
  `:AiderSendNo`)
- `AiderExec`: Send the prompt written in cmdline to aider with `/` prefix completion
- `AiderSetArgs`: set the command line args to launch aider with autocompletion (e.g. `AiderSetArgs --model gpt-4o`)

## Keymaps

In addition to the general `<plug>` keymap created by yarepl.nvim (for example
`<Plug>(REPLSendLine-aider)`), aider.lua provides a set of additional `<Plug>`
mappings to enhanve the experience with aider. Here are the
available `<Plug>` mappings:

- `<Plug>(AiderExec)`: Type the prompt in cmdline and send it to aider.
- `<Plug>(AiderSendYes)`: Send 'y' (Yes) to aider
- `<Plug>(AiderSendNo)`: Send 'n' (No) to aider
- `<Plug>(AiderSendAbort)`: Send abort signal (C-c) to aider
- `<Plug>(AiderSendExit)`: Send exit signal (C-d) to aider

## Usage

Make sure you have added aider into your repl meta:

```lua
require('yarepl').setup {
    metas = { aider = require('yarepl.extensions.aider').create_aider_meta() }
}
```

### Example keybinding Setup

Here's an example of how you can set up your keybindings in your Neovim
configuration:

In this example, `<Leader>a` is used as the prefix for aider-related
keybindings. You can customize these to your preference.

For more detailed information on using aider, refer to the [aider
documentation](https://aider.chat/).

```lua
local keymap = vim.api.nvim_set_keymap

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
```

## Customization

`yarepl.extensions.aider` comes with the following default:

```lua
require('yarepl.extensions.aider').setup {
    aider_cmd = 'aider',
    --NOTE: make sure you pass a list of string, not string,
    aider_args = { '--watch-files' },
    -- The default wincmd is to open aider in a floating window
    wincmd = ...
}
```

## Note

I recommend trying the `inline comment as instruction` feature in `aider`,
which is enabled by default for `yarepl.extensions.aider`. See the
[documentation](https://aider.chat/docs/usage/watch.html).
