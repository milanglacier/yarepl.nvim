- [Aider](#aider)
  - [Overview](#overview)
  - [Features](#features)
  - [Commands](#commands)
  - [Keymaps](#keymaps)
  - [Usage](#usage)
    - [Example keybinding Setup](#example-keybinding-setup)
  - [Customization](#customization)
  - [Note](#note)
- [Codex](#codex)
  - [Overview](#overview-1)
  - [Features](#features-1)
  - [Commands](#commands-1)
  - [Keymaps](#keymaps-1)
  - [Usage](#usage-1)
    - [Example keybinding Setup](#example-keybinding-setup-1)
  - [Customization](#customization-1)
- [OpenCode](#opencode)
  - [Overview](#overview-2)
  - [Features](#features-2)
  - [Commands](#commands-2)
  - [Keymaps](#keymaps-2)
  - [Usage](#usage-2)
    - [Example keybinding Setup](#example-keybinding-setup-2)
  - [Customization](#customization-2)
- [Code Cell](#code-cell)
  - [Overview](#overview-3)
  - [Features](#features-3)
  - [Usage](#usage-3)
    - [Example Configuration](#example-configuration)
- [Telescope Integration](#telescope-integration)
- [Fzf-lua Integration](#fzf-lua-integration)
- [Snacks.picker Integration](#snackspicker-integration)

**Breaking change:** extension `<Plug>` mappings now use lowercase `yarepl`
names. Update old forms like `<Plug>(Yarepl-aider-send-visual)`, to
`<Plug>(yarepl-aider-send-visual)`,

Aider, Codex, and OpenCode also live under the unified `Yarepl` command tree.
The old top-level commands are being replaced by forms like `:Yarepl aider
exec`, `:Yarepl aider set_prefix /ask`, `:Yarepl codex send_status`, `:Yarepl
codex send_open_editor`, and `:Yarepl opencode send_models`.

If you were used to `AiderExec`, `AiderSetPrefix`, `CodexExec`, or
`<Plug>(AiderSendYes)`, the new names are the same actions with a more regular
shape: snake-style subcommands on the command line, kebab-style names inside
`<Plug>(...)`.

The legacy commands and keymaps (`REPL*`) still function for now, but they will
be removed on `2026-06-01`.

This keeps the extension side predictable. You get one command namespace, the
same completion behavior everywhere, and a single place to add new actions
instead of another standalone command for each one.

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

The `yarepl.extensions.aider` module offers command-line completions for the
unified Aider subcommands.

- `Yarepl aider set_prefix`: Specify a `/` prefix for Aider commands, such as
  `/ask`, `/architect`, `/context`, etc. When sending buffer content to the
  Aider REPL, the specified prefix will be prepended to the buffer content.
- `Yarepl aider remove_prefix`: Remove the current prefix.
- `Yarepl aider send_yes`: Send `y` to aider.
- `Yarepl aider send_no`: Send `n` to aider.
- `Yarepl aider send_abort`: Send abort signal (`C-c`) to aider.
- `Yarepl aider send_exit`: Send exit signal (`C-d`) to aider.
- `Yarepl aider send_diff`: Send `/diff` to aider.
- `Yarepl aider send_paste`: Send `/paste` to aider, particularly useful for
  sending images.
- `Yarepl aider send_clear`: Send `/clear` to aider.
- `Yarepl aider send_undo`: Send `/undo` to aider.
- `Yarepl aider send_reset`: Send `/reset` to aider.
- `Yarepl aider send_drop`: Send `/drop` to aider.
- `Yarepl aider send_ls`: Send `/ls` to aider.
- `Yarepl aider send_ask_mode`: Switch aider to _ask_ mode.
- `Yarepl aider send_arch_mode`: Switch aider to _architect_ mode.
- `Yarepl aider send_code_mode`: Switch aider to _code_ mode.
- `Yarepl aider send_context_mode`: Switch aider to _context_ mode.

  **Note**: `send_context_mode` requires `aider v0.79.0+`

- `Yarepl aider exec`: Send the prompt written in cmdline to aider with `/`
  prefix completion.
- `Yarepl aider set_args`: Set the command line args to launch aider with
  autocompletion, for example `Yarepl aider set_args --model gpt-4o`.

## Keymaps

In addition to the general `<Plug>` maps created by yarepl.nvim, aider.lua
provides a set of additional `<Plug>` mappings to enhance the experience with
aider:

- `<Plug>(yarepl-aider-send-line)`: Send current line to aider.
- `<Plug>(yarepl-aider-send-visual)`: Send visual selection to aider.
- `<Plug>(yarepl-aider-send-operator)`: Operator to send text to aider.
- `<Plug>(yarepl-aider-exec)`: Type the prompt in cmdline and send it to aider.
- `<Plug>(yarepl-aider-send-yes)`: Send `y` to aider.
- `<Plug>(yarepl-aider-send-no)`: Send `n` to aider.
- `<Plug>(yarepl-aider-send-abort)`: Send abort signal (`C-c`) to aider.
- `<Plug>(yarepl-aider-send-exit)`: Send exit signal (`C-d`) to aider.
- `<Plug>(yarepl-aider-send-diff)`
- `<Plug>(yarepl-aider-send-paste)`: Send `/paste`, particularly useful for
  sending images.
- `<Plug>(yarepl-aider-send-clear)`
- `<Plug>(yarepl-aider-send-undo)`
- `<Plug>(yarepl-aider-send-reset)`
- `<Plug>(yarepl-aider-send-drop)`
- `<Plug>(yarepl-aider-send-ls)`
- `<Plug>(yarepl-aider-send-ask-mode)`: Switch aider to _ask_ mode.
- `<Plug>(yarepl-aider-send-arch-mode)`: Switch aider to _architect_ mode.
- `<Plug>(yarepl-aider-send-code-mode)`: Switch aider to _code_ mode.
- `<Plug>(yarepl-aider-send-context-mode)`: Switch aider to _context_ mode.

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
keymap('n', '<Leader>cs', '<Plug>(yarepl-start-aider)', { desc = 'Start aider' })
keymap('n', '<Leader>cf', '<Plug>(yarepl-focus-aider)', { desc = 'Focus aider' })
keymap('n', '<Leader>ch', '<Plug>(yarepl-hide-aider)', { desc = 'Hide aider' })
keymap('v', '<Leader>cr', '<Plug>(yarepl-send-visual-aider)', { desc = 'Send visual to aider' })
keymap('n', '<Leader>crr', '<Plug>(yarepl-send-line-aider)', { desc = 'Send line to aider' })
keymap('n', '<Leader>cr', '<Plug>(yarepl-send-operator-aider)', { desc = 'Send operator to aider' })

-- special keymap from aider
keymap('n', '<Leader>ae', '<Plug>(yarepl-aider-exec)', {
    desc = 'Execute command in aider',
})
keymap('n', '<Leader>ay', '<Plug>(yarepl-aider-send-yes)', {
    desc = 'Send y to aider',
})
keymap('n', '<Leader>an', '<Plug>(yarepl-aider-send-no)', {
    desc = 'Send n to aider',
})
keymap('n', '<Leader>ap', '<Plug>(yarepl-aider-send-paste)', {
    desc = 'Send /paste to aider',
})
keymap('n', '<Leader>aa', '<Plug>(yarepl-aider-send-abort)', {
    desc = 'Send abort to aider',
})
keymap('n', '<Leader>aq', '<Plug>(yarepl-aider-send-exit)', {
    desc = 'Send exit to aider',
})
keymap('n', '<Leader>ag', '<cmd>Yarepl aider set_prefix<cr>', {
    desc = 'set aider prefix',
})
keymap('n', '<Leader>ama', '<Plug>(yarepl-aider-send-ask-mode)', {
    desc = 'Switch aider to ask mode',
})
keymap('n', '<Leader>amA', '<Plug>(yarepl-aider-send-arch-mode)', {
    desc = 'Switch aider to architect mode',
})
keymap('n', '<Leader>amc', '<Plug>(yarepl-aider-send-code-mode)', {
    desc = 'Switch aider to code mode',
})
keymap('n', '<Leader>aG', '<cmd>Yarepl aider remove_prefix<cr>', {
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
    -- Display a winbar (e.g., "aider#<id>") in the floating window.
    show_winbar_in_float_win = true,
    -- The default wincmd is to open aider in a floating window at the bottom-right corner
    wincmd = require('yarepl.extensions.aider').config.wincmd,
}
```

## Note

I recommend explore the `inline comment as instruction` feature in `aider`,
which is enabled by default for this extension. See the
[documentation](https://aider.chat/docs/usage/watch.html).

# Codex

## Overview

This extension integrates the Codex CLI with yarepl to provide a smooth
workflow inside Neovim. It offers commands, keymaps, and a ready-to-use meta to
launch and interact with Codex.

## Features

- Seamless yarepl integration for Codex sessions
- Completions for common slash-style Codex commands
- Predefined shortcuts for frequent actions (Abort, Exit, Diff, Status, etc.)
- Configurable Codex command and arguments
- Floating window default for a focused REPL experience

## Commands

- `Yarepl codex set_args`: Set CLI arguments for launching Codex with
  completion support, for example `Yarepl codex set_args --model gpt-5`.
- `Yarepl codex send_abort`: Send Ctrl-C to Codex.
- `Yarepl codex send_exit`: Send Ctrl-D to Codex.
- `Yarepl codex send_diff`: Send `/diff` to Codex.
- `Yarepl codex send_status`: Send `/status` to Codex.
- `Yarepl codex send_model`: Send `/model` to Codex.
- `Yarepl codex send_new`: Send `/new` to Codex.
- `Yarepl codex send_approvals`: Send `/approvals` to Codex.
- `Yarepl codex send_compact`: Send `/compact` to Codex.
- `Yarepl codex send_open_editor`: Ask Codex to open the editor (`Ctrl-G`).
- `Yarepl codex send_transcript_enter`: Send `Ctrl-T`.
- `Yarepl codex send_transcript_quit`: Send `q`.
- `Yarepl codex send_transcript_begin`: Send `Home`.
- `Yarepl codex send_transcript_end`: Send `End`.
- `Yarepl codex send_page_up`: Send `PageUp`.
- `Yarepl codex send_page_down`: Send `PageDown`.
- `Yarepl codex exec`: Type a prompt or slash command in the cmdline and send
  it to Codex, with completion for common prefixes like `/model`,
  `/approvals`, `/init`, `/new`, `/compact`, `/diff`, `/mention`, `/status`.

All commands accept an optional count to target a specific Codex REPL id.

## Keymaps

In addition to the general `<Plug>` maps created by yarepl once the `codex`
meta is registered (e.g. `<Plug>(yarepl-codex-send-line)`), this extension
defines extra convenience maps:

- `<Plug>(yarepl-codex-exec)`: Type in cmdline and send to Codex.
- `<Plug>(yarepl-codex-send-abort)`: Send Ctrl-C.
- `<Plug>(yarepl-codex-send-exit)`: Send Ctrl-D.
- `<Plug>(yarepl-codex-send-diff)`
- `<Plug>(yarepl-codex-send-status)`
- `<Plug>(yarepl-codex-send-model)`
- `<Plug>(yarepl-codex-send-new)`
- `<Plug>(yarepl-codex-send-approvals)`
- `<Plug>(yarepl-codex-send-compact)`
- `<Plug>(yarepl-codex-send-open-editor)`: Ask Codex to open the editor
  (`Ctrl-G`).
- `<Plug>(yarepl-codex-send-transcript-enter)`
- `<Plug>(yarepl-codex-send-transcript-quit)`
- `<Plug>(yarepl-codex-send-transcript-begin)`: Send `<Home>`.
- `<Plug>(yarepl-codex-send-transcript-end)`: Send `<End>`.
- `<Plug>(yarepl-codex-send-page-up)`
- `<Plug>(yarepl-codex-send-page-down)`

You can prefix a count (e.g. `2`) before a mapping to target that REPL id.

## Usage

Add the Codex meta to your setup:

```lua
require('yarepl').setup {
  metas = {
    codex = require('yarepl.extensions.codex').create_codex_meta(),
  },
}
```

For the best experience using the `Open Editor` (Ctrl‑G) command with Codex,
install the [neovim-remote](https://github.com/mhinz/neovim-remote) plugin
(until Neovim provides an official `--remote-wait`) and set your `EDITOR`
inside Neovim to an `nvr` command. For example:

```lua
vim.env.EDITOR = 'nvr -cc tabnew --remote-wait'
```

To return from an nvr instance to Codex, use `:w | bdelete` instead of `:wq`,
as nvr only exits when the buffer is deleted, allowing Codex to receive the
updated content. You can also define a convenient `WQ` command with this
Vimscript one-liner:

```vim
command! WQ w | bdelete
```

### Example keybinding Setup

```lua
local keymap = vim.api.nvim_set_keymap

-- general yarepl keymaps for the codex meta
keymap('n', '<Leader>cs', '<Plug>(yarepl-start-codex)', { desc = 'Start codex' })
keymap('n', '<Leader>cf', '<Plug>(yarepl-focus-codex)', { desc = 'Focus codex' })
keymap('n', '<Leader>ch', '<Plug>(yarepl-hide-codex)', { desc = 'Hide codex' })
keymap('v', '<Leader>cr', '<Plug>(yarepl-send-visual-codex)', { desc = 'Send visual to codex' })
keymap('n', '<Leader>crr', '<Plug>(yarepl-send-line-codex)', { desc = 'Send line to codex' })
keymap('n', '<Leader>cr', '<Plug>(yarepl-send-operator-codex)', { desc = 'Send operator to codex' })

-- codex-specific convenience keymaps
keymap('n', '<Leader>ce', '<Plug>(yarepl-codex-exec)', { desc = 'Exec in Codex' })
keymap('n', '<Leader>ca', '<Plug>(yarepl-codex-send-abort)', { desc = 'Abort' })
keymap('n', '<Leader>cD', '<Plug>(yarepl-codex-send-exit)', { desc = 'Exit' })
keymap('n', '<Leader>cd', '<Plug>(yarepl-codex-send-diff)', { desc = 'Diff' })
keymap('n', '<Leader>ct', '<Plug>(yarepl-codex-send-status)', { desc = 'Status' })
keymap('n', '<Leader>cm', '<Plug>(yarepl-codex-send-model)', { desc = 'Model' })
keymap('n', '<Leader>cn', '<Plug>(yarepl-codex-send-new)', { desc = 'New' })
keymap('n', '<Leader>cA', '<Plug>(yarepl-codex-send-approvals)', { desc = 'Approvals' })
keymap('n', '<Leader>cc', '<Plug>(yarepl-codex-send-compact)', { desc = 'Compact' })
keymap('n', '<Leader>co', '<Plug>(yarepl-codex-send-open-editor)', { desc = 'Open editor' })
-- transcript and navigation helpers
keymap('n', '<Leader>cte', '<Plug>(yarepl-codex-send-transcript-enter)', { desc = 'Transcript mode' })
keymap('n', '<Leader>ctq', '<Plug>(yarepl-codex-send-transcript-quit)', { desc = 'Transcript quit' })
keymap('n', '<Leader>ctg', '<Plug>(yarepl-codex-send-transcript-begin)', { desc = 'Transcript begin' })
keymap('n', '<Leader>ctG', '<Plug>(yarepl-codex-send-transcript-end)', { desc = 'Transcript end' })
keymap('n', '<Leader>ctk', '<Plug>(yarepl-codex-send-page-up)', { desc = 'Transcript page up' })
keymap('n', '<Leader>ctj', '<Plug>(yarepl-codex-send-page-down)', { desc = 'Transcript page down' })
keymap('n', '<Leader>c<space>', '<cmd>checktime<cr>', {
    desc = 'sync file changes by codex to nvim buffer',
})
```

## Customization

Default configuration:

```lua
require('yarepl.extensions.codex').setup {
      codex_cmd = 'codex',
      codex_args = {},
      -- Warn when $EDITOR is unset or not using nvr (for OpenEditor).
      warn_on_EDITOR_env_var = true,
      -- Display a winbar (e.g., "codex#<id>") in the floating window.
      show_winbar_in_float_win = true,
      -- The default is a floating window at the bottom right corner; you can override it
      wincmd = require('yarepl.extensions.codex').config.wincmd,
}
```

# OpenCode

## Overview

This extension integrates the OpenCode with yarepl. It provides a ready to use
REPL meta, completions for common slash commands, and convenience commands for
the most used TUI keybinds.

## Features

- Seamless yarepl integration for OpenCode sessions
- Completions for common OpenCode slash commands
- Convenience shortcuts for OpenCode's `ctrl+x` leader commands
- Configurable OpenCode command and arguments
- Floating window default for a focused REPL experience

## Commands

- `Yarepl opencode set_args`: Set CLI arguments for launching OpenCode with
  completion support, for example `Yarepl opencode set_args --model xxx`
- `Yarepl opencode send_compact`: Send `/compact` to OpenCode.
- `Yarepl opencode send_connect`: Send `/connect` to OpenCode.
- `Yarepl opencode send_open_editor`: Send `ctrl+x e` to OpenCode.
- `Yarepl opencode send_exit`: Send `/exit` to OpenCode.
- `Yarepl opencode send_export`: Send `/export` to OpenCode.
- `Yarepl opencode send_help`: Send `/help` to OpenCode.
- `Yarepl opencode send_init`: Send `/init` to OpenCode.
- `Yarepl opencode send_models`: Send `/models` to OpenCode.
- `Yarepl opencode send_new`: Send `/new` to OpenCode.
- `Yarepl opencode send_redo`: Send `/redo` to OpenCode.
- `Yarepl opencode send_sessions`: Send `/sessions` to OpenCode.
- `Yarepl opencode send_share`: Send `/share` to OpenCode.
- `Yarepl opencode send_thinking`: Send `/thinking` to OpenCode.
- `Yarepl opencode send_undo`: Send `/undo` to OpenCode.
- `Yarepl opencode send_unshare`: Send `/unshare` to OpenCode.
- `Yarepl opencode send_scroll_up`: Send `ctrl+alt+u` to OpenCode.
- `Yarepl opencode send_scroll_down`: Send `ctrl+alt+d` to OpenCode.
- `Yarepl opencode exec`: Send the prompt written in cmdline to OpenCode, with
  completion for common prefixes like `/compact`, `/connect`, `/editor`,
  `/models`, `/sessions`, `/thinking`, and `/undo`.

All commands accept an optional count to target a specific OpenCode REPL id.

## Keymaps

In addition to the general `<Plug>` maps created by yarepl once the `opencode`
meta is registered, this extension defines extra convenience maps:

- `<Plug>(yarepl-opencode-exec)`: Type in cmdline and send to OpenCode.
- `<Plug>(yarepl-opencode-send-compact)`
- `<Plug>(yarepl-opencode-send-connect)`
- `<Plug>(yarepl-opencode-send-open-editor)`: Send `ctrl+x e`.
- `<Plug>(yarepl-opencode-send-exit)`
- `<Plug>(yarepl-opencode-send-export)`
- `<Plug>(yarepl-opencode-send-help)`
- `<Plug>(yarepl-opencode-send-init)`
- `<Plug>(yarepl-opencode-send-models)`
- `<Plug>(yarepl-opencode-send-new)`
- `<Plug>(yarepl-opencode-send-redo)`
- `<Plug>(yarepl-opencode-send-sessions)`
- `<Plug>(yarepl-opencode-send-share)`
- `<Plug>(yarepl-opencode-send-thinking)`
- `<Plug>(yarepl-opencode-send-undo)`
- `<Plug>(yarepl-opencode-send-unshare)`
- `<Plug>(yarepl-opencode-send-scroll-up)`: Send `ctrl+alt+u`.
- `<Plug>(yarepl-opencode-send-scroll-down)`: Send `ctrl+alt+d`.

You can prefix a count (e.g. `2`) before a mapping to target that REPL id.

## Usage

Add the OpenCode meta to your setup:

```lua
require('yarepl').setup {
  metas = {
    opencode = require('yarepl.extensions.opencode').create_opencode_meta(),
  },
}
```

### Example keybinding Setup

```lua
local keymap = vim.api.nvim_set_keymap

-- general yarepl keymaps for the opencode meta
keymap('n', '<Leader>os', '<Plug>(yarepl-start-opencode)', { desc = 'Start OpenCode' })
keymap('n', '<Leader>of', '<Plug>(yarepl-focus-opencode)', { desc = 'Focus OpenCode' })
keymap('n', '<Leader>oh', '<Plug>(yarepl-hide-opencode)', { desc = 'Hide OpenCode' })
keymap('v', '<Leader>or', '<Plug>(yarepl-send-visual-opencode)', { desc = 'Send visual to OpenCode' })
keymap('n', '<Leader>orr', '<Plug>(yarepl-send-line-opencode)', { desc = 'Send line to OpenCode' })
keymap('n', '<Leader>or', '<Plug>(yarepl-send-operator-opencode)', { desc = 'Send operator to OpenCode' })

-- opencode-specific convenience keymaps
keymap('n', '<Leader>oe', '<Plug>(yarepl-opencode-exec)', { desc = 'Exec in OpenCode' })
keymap('n', '<Leader>oo', '<Plug>(yarepl-opencode-send-open-editor)', { desc = 'Open editor' })
keymap('n', '<Leader>ou', '<Plug>(yarepl-opencode-send-scroll-up)', { desc = 'Scroll up' })
keymap('n', '<Leader>od', '<Plug>(yarepl-opencode-send-scroll-down)', { desc = 'Scroll down' })
```

## Customization

Default configuration:

```lua
require('yarepl.extensions.opencode').setup {
      opencode_cmd = 'opencode',
      opencode_args = {},
      -- Display a winbar (e.g., "opencode#<id>") in the floating window.
      show_winbar_in_float_window = true,
      -- The default is a floating window at the bottom right corner; you can override it
      wincmd = require('yarepl.extensions.opencode').config.wincmd,
}
```

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

To send code cells to REPL, map `<Plug>(yarepl-send-operator)` to `<Leader>s`, then
use `<Leader>sic` to send the current cell.

# Telescope Integration

`yarepl` has integrated with Telescope and can be enabled by adding the
following line to your config:

```lua
require('telescope').load_extension 'yarepl_show'
```

Once added, you can use `Telescope yarepl_show` to preview the active REPL
buffers. This integration allows you to preview active REPL buffers. Pressing
`<CR>` will open the selected REPL buffer using `wincmd`, either with a
meta-local `wincmd` or the global `wincmd`, depending on the context.

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
