# Version 0.12.0 (2026-01-23)

## Features

- **REPLStartOrHideOrFocus**: Added a new command `REPLStartOrHideOrFocus` to
  Toggles the visibility (focus/hide) of an existing REPL, or creates a new one
  if it does not exist.
- **Highlight Range**: Added an option to highlight the region sent to the REPL.
- **Character-wise Sending**: Added support for sending character-wise regions to the REPL.
- **Source Command Hint**: Added `show_source_command_hint` option to display
  the first line of the source command as virtual text.
- **Formatter**: Added `bracketed_pasting_delayed_cr` formatter for better
  compatibility with REPLs like Claude Code and OpenAI Codex.
- **Extensions (Codex/Aider)**:
  - Added a new extension for OpenAI's Codex.
  - Display the REPL name and ID in the winbar for the default `wincmd` in
    Aider and Codex.
  - Default floating window position changed to bottom-right corner.

## Breaking Change

- **REPLStart**: The semantics have changed. When a name is provided (e.g.,
  `2REPLStart ipython`), the count now refers to the Nth _matching_ REPL, rather
  than the global REPL ID. When the count is not provided, it now forces the
  creation of a new REPL instance instead of focusing an existing REPL with ID
  `1`.
- **Config**: Removed `source_func` option. Use `source_syntax` instead, which
  now accepts both string syntax values and functions.
- **OS/Windows**: Renamed `os.windows.send_delayed_cr_after_sending` to
  `os.windows.send_delayed_final_cr` to align with REPL meta options.
- **Extensions**: Codex and Aider floating windows now default to the
  bottom-right corner instead of occupying most of the screen.

## Bug Fixes

- **IPython Source**: Fixed temporary file handling in IPython source function
  to allow proper PDB debugging context.

# Version 0.11 (2025-04-08)

## Features

- Added command `REPLSourceOperator` and `REPLSourceVisual`
  See [comparison in
  README](https://github.com/milanglacier/yarepl.nvim?tab=readme-ov-file#replsourcevisual)
  for a detailed comparison between `REPLSendVisual` and `REPLSourceVisual`.

# Version 0.10.1 (2025-02-14)

- Add luarocks release

# Version 0.10 (2025-02-08)

- Initial release
