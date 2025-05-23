- [Aider](#aider)
  - [Overview](#overview)
  - [Features](#features)
  - [Commands](#commands)
  - [Keymaps](#keymaps)
  - [Usage](#usage)
    - [Example keybinding Setup](#example-keybinding-setup)
  - [Customization](#customization)
  - [Note](#note)
- [Code Cell](#code-cell)
  - [Overview](#overview-1)
  - [Features](#features-1)
  - [Usage](#usage-1)
    - [Example Configuration](#example-configuration)
- [Telescope Integration](#telescope-integration)
- [Fzf-lua Integration](#fzf-lua-integration)
- [Snacks.picker Integration](#snackspicker-integration)

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
  `/architect`, `/context` etc. When sending buffer content to the Aider REPL,
  the specified prefix will be prepended to the buffer content.
- `AiderRemovePrefix`: Remove the current prefix
- `AiderSend<Action>`: Send specific actions to aider (e.g., `:AiderSendYes`,
  `:AiderSendNo`). Available action: `Yes`, `No`, `Abort`, `Diff`, `Paste`,
  `Clear`, `Undo`, `Reset`, `Drop`, `Ls`, `AskMode`, `ArchMode`, `CodeMode`,
  `ContextMode`.

  **Note**: `ContextMode` requires `aider v0.79.0+`

- `AiderExec`: Send the prompt written in cmdline to aider with `/` prefix completion
- `AiderSetArgs`: set the command line args to launch aider with autocompletion (e.g. `AiderSetArgs --model gpt-4o`)

## Keymaps

In addition to the general `<plug>` keymap created by yarepl.nvim (for example
`<Plug>(REPLSendLine-aider)`), aider.lua provides a set of additional `<Plug>`
mappings to enhance the experience with aider. Here are the
available `<Plug>` mappings:

- `<Plug>(REPLSendLine-aider)`: Send current line to aider
- `<Plug>(REPLSendVisual-aider)`: Send visual selection to aider
- `<Plug>(REPLSendOperator-aider)`: Operator to send text to aider
- `<Plug>(AiderExec)`: Type the prompt in cmdline and send it to aider.
- `<Plug>(AiderSendYes)`: Send 'y' (Yes) to aider
- `<Plug>(AiderSendNo)`: Send 'n' (No) to aider
- `<Plug>(AiderSendAbort)`: Send abort signal (C-c) to aider
- `<Plug>(AiderSendExit)`: Send exit signal (C-d) to aider
- `<Plug>(AiderSendDiff)`
- `<Plug>(AiderSendPaste)`: send `/paste` command, particularly useful for sending images
- `<Plug>(AiderSendClear)`
- `<Plug>(AiderSendUndo)`
- `<Plug>(AiderSendReset)`
- `<Plug>(AiderSendDrop)`
- `<Plug>(AiderSendLs)`
- `<Plug>(AiderSendAskMode)`: switch aider to _ask_ mode
- `<Plug>(AiderSendArchMode)`: switch aider to _architect_ mode
- `<Plug>(AiderSendCodeMode)`: switch aider to _code_ mode
- `<Plug>(AiderSendContextMode)`: switch aider to _context_ mode

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
keymap('n', '<Leader>ap', '<Plug>(AiderSendPaste)', {
    desc = 'Send /paste to aider',
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
keymap('n', '<Leader>ama', '<Plug>(AiderSendAskMode)', {
    desc = 'Switch aider to ask mode',
})
keymap('n', '<Leader>amA', '<Plug>(AiderSendArchMode)', {
    desc = 'Switch aider to architect mode',
})
keymap('n', '<Leader>amc', '<Plug>(AiderSendCodeMode)', {
    desc = 'Switch aider to code mode',
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
    wincmd = require('yarepl.extensions.aider').wincmd,
}
```

## Note

I recommend explore the `inline comment as instruction` feature in `aider`,
which is enabled by default for this extension. See the
[documentation](https://aider.chat/docs/usage/watch.html).

# Code Cell

## Overview

The code cell extension provides text objects for working with code cells in various file types. Code cells are sections of code delimited by specific patterns, commonly used in literate programming and notebook-style documents.

## Features

- Text objects for selecting code cells
- Support for both "inner" and "around" selections
- Configurable patterns for different file types
- Automatic setup based on file type

## Usage

The extension creates text objects for code cell selection using defined start
and end patterns.

### Example Configuration

The module requires explicit configuration to activate, as it has no default
settings. Below is a sample configuration that enables:

- Markdown-style code blocks (triple backticks) in rmd, quarto, and markdown files
- Python/R-style code cells (`# %%`) in python and R files

````lua
require('yarepl.extensions.code_cell').register_text_objects {
    {
        key = 'c',
        start_pattern = '```.+',
        end_pattern = '^```$',
        ft = { 'rmd', 'quarto', 'markdown' },
        desc = 'markdown code cells',
    },
    {
        key = '<Leader>c',
        start_pattern = '^# ?%%%%.*',
        end_pattern = '^# ?%%%%.*',
        ft = { 'r', 'python' },
        desc = 'r/python code cells',
    },
}
````

**Usage Examples**:

Markdown files (using key `c`):

- `ic`: Select cell content (excludes delimiters)
- `ac`: Select entire cell (includes delimiters)

Python/R files (using `<Leader>c`):

- `i<Leader>c`: Select content between `# %%` markers
- `a<Leader>c`: Select content including `# %%` markers

Note: Use Lua patterns rather than Vim regex patterns.

These text objects function in both operator-pending and visual modes.

To send code cells to REPL, map `<Plug>(REPLSendOperator)` to `<Leader>s`, then
use `<Leader>sic` to send the current cell.

# Telescope Integration

`yarepl` has integrated with Telescope and can be enabled by adding the
following line to your config:

```lua
require('telescope').load_extension 'REPLShow'
```

Once added, you can use `Telescope REPLShow` to preview the active REPL
buffers. If you are using the default Telescope configuration, `<C-t>` opens a
new tab for the selected REPL, `<C-v>` generates a vertical split window for
the chosen REPL, and `<C-x>` creates a horizontal split window for your
selected REPL.

# Fzf-lua Integration

`yarepl` has integrated with `Fzf-lua` and can be enabled by adding the
following line to your config:

```lua
vim.keymap.set('n', '<Leader>rv', function() require('yarepl.extensions.fzf').repl_show() end)
```

This integration allows you to preview active REPL buffers. Pressing `<CR>`
will open the selected REPL buffer using `wincmd`, either with a meta-local
`wincmd` or the global `wincmd`, depending on the context.

For users familiar with `Fzf-lua`'s API, custom options can be passed to the
function to tailor its behavior, similar to any other `Fzf-lua` pickers. For
example:

```lua
require('yarepl.extensions.fzf').repl_show {
    winopts = {
        title = 'REPL>',
        previewer = {
            layout = 'horizontal'
        }
    }
}
```

# Snacks.picker Integration

`yarepl` has integrated with `Snacks.picker` and can be enabled by adding the
following line to your config:

```lua
vim.keymap.set('n', '<Leader>rv', function() require('yarepl.extensions.snacks').repl_show() end)
```

This integration allows you to preview active REPL buffers. Pressing `<CR>`
will open the selected REPL buffer using `wincmd`, either with a meta-local
`wincmd` or the global `wincmd`, depending on the context.

For users familiar with `Snacks.picker`'s API, custom options can be passed to
the function to tailor its behavior, similar to other `Snacks` pickers.

```lua
require('yarepl.extensions.snacks').repl_show {
    prompt = 'Yarepl REPL',
}
```
