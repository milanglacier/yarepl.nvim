# Repository Guidelines

## Project Structure & Module Organization

- `lua/yarepl/` contains core plugin logic, REPL management, and built-in commands.
- `lua/yarepl/extensions/` hosts optional integrations (aider, codex, code-cell, fzf, snacks).
- `lua/telescope/_extensions/` provides the telescope REPL picker integration.
- `extensions/README.md` documents extension usage and keymaps.
- `assets/` stores screenshots used in the README.

## Build, Test, and Development Commands

There is no build step; this is a Lua-based Neovim plugin.

- Manual validation: open Neovim and `:Lazy load yarepl.nvim` or `:source` your config to test behavior.

## Coding Style & Naming Conventions

- Indentation: 4 spaces in Lua files (no tabs).
- Lua modules are named by path (e.g., `require('yarepl.extensions.aider')`).
- Prefer descriptive module/file names over abbreviations.
- Keep new user-facing commands consistent with existing `REPL*` naming.

## Testing Guidelines

- No automated test suite is currently present.
- If you add tests, document the framework and commands in this file and the README.

## Commit & Pull Request Guidelines

- Commit messages follow a Conventional Commits style, e.g., `feat: add option`, `fix: update logic`, `doc: update codex doc.`
- PRs should include:
  - A clear summary of behavior changes.
  - Any relevant Neovim version requirements.
  - Screenshots/GIFs for UI/UX changes (especially for picker or window behavior).

## Agent-Specific Instructions

- Follow `AGENTS.md` in the repo root for contributor guidance.
