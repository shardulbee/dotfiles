# TurboCode

Custom productivity utilities for VS Code.

## Features

- **Open GitHub Permalink**: Opens a permalink to the current line or selection in GitHub using the current commit SHA
- **Open GitHub Permalink on Main**: Opens a permalink to the current line or selection in GitHub using the main branch

## Usage

1. Open a file in a git repository with a GitHub remote
2. Place your cursor on a line or select multiple lines
3. Run one of the commands:
   - `TurboCode: Open GitHub Permalink` - Uses current commit SHA
   - `TurboCode: Open GitHub Permalink on Main` - Uses main branch

## Requirements

- File must be in a git repository
- Repository must have an `origin` remote pointing to GitHub

