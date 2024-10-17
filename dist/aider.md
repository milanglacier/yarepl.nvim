# aider.lua for yarepl.nvim

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

- `AiderArgs`: Set command-line arguments for aider
- `AiderSetPrefix`: Set a prefix for aider commands (with autocompletion)
- `AiderRemovePrefix`: Remove the current prefix
- `AiderSend<Action>`: Send specific actions to aider (e.g., `:AiderSendYes`,
  `:AiderSendNo`)
- `AiderExec`: Send the prompt written in cmdline to aider (with autocompletion)
- `AiderArgs`: set the additional args to launch aider with autocompletion (e.g. `AiderArgs --model gpt-4o`)

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

### Example keybinding Setup

Here's an example of how you can set up your keybindings in your Neovim
configuration:

In this example, `<Leader>a` is used as the prefix for aider-related
keybindings. You can customize these to your preference.

For more detailed information on using aider, refer to the [aider
documentation](https://aider.chat/).

## Customization
