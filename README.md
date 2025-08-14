# Claude Code Windows Installer

A one-click installer for Claude Code on Windows that automatically handles all dependencies.

## Features

- ✅ **No admin rights required** - Installs everything in user space
- ✅ **No Node.js required** - Uses native binary installer
- ✅ **No winget required** - Direct downloads only
- ✅ **Automatic Git installation** - Installs Portable Git if not present
- ✅ **PATH configuration** - Automatically configures environment variables
- ✅ **Architecture detection** - Supports both x64 and ARM64 Windows

## Quick Start

### Option 1: Download and Run (Recommended)

1. Download `setup-claude-code.cmd` from the [latest release](../../releases/latest)
2. Double-click to run
3. Follow the prompts
4. Run `claude login` when complete

### Option 2: Direct Download Link

Run this in Command Prompt or PowerShell:

```cmd
curl -O https://github.com/[your-username]/[your-repo]/releases/latest/download/setup-claude-code.cmd && setup-claude-code.cmd
```

## What It Does

1. **Checks for Git Bash** - Uses existing installation or installs Portable Git
2. **Sets up environment** - Configures `CLAUDE_CODE_GIT_BASH_PATH`
3. **Installs Claude Code** - Downloads and installs via official installer
4. **Configures PATH** - Adds Claude Code to your PATH
5. **Verifies installation** - Runs `claude --version` and `claude doctor`

## System Requirements

- Windows 10/11 (x64 or ARM64)
- Internet connection
- ~200MB free disk space

## Troubleshooting

### "claude" command not found after installation
- Close and reopen your terminal
- The installer updates your PATH, but existing terminals need to be restarted

### Installation fails with network error
- Check your internet connection
- Try running the installer again
- If behind a corporate proxy, see [Claude Code proxy documentation](https://docs.anthropic.com/en/docs/claude-code/corporate-proxy)

### Git installation fails
- The script will automatically download Portable Git if needed
- If it fails, you can manually install [Git for Windows](https://git-scm.com/download/win) first

## Manual Installation

If the automated installer doesn't work, follow the [official documentation](https://docs.anthropic.com/en/docs/claude-code/setup).

## Support

- Claude Code Documentation: https://docs.anthropic.com/en/docs/claude-code
- Report issues: https://github.com/anthropics/claude-code/issues

## License

This installer script is provided as-is to help Windows users get started with Claude Code more easily.