# TurboCode Extension Usage Guide

## Installation

1. Open this folder in VS Code
2. Press `F5` to launch the Extension Development Host
3. In the new window, open a file from a Git repository with a GitHub remote

## Testing the Commands

### Test 1: Open GitHub Permalink (with current SHA)

1. Open a file in a git repository
2. Place your cursor on a line
3. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
4. Type "TurboCode: Open GitHub Permalink" and press Enter
5. Your browser should open with a GitHub URL pointing to that line using the current commit SHA

### Test 2: Open GitHub Permalink on Main

1. Open a file in a git repository
2. Place your cursor on a line
3. Open the Command Palette
4. Type "TurboCode: Open GitHub Permalink on Main" and press Enter
5. Your browser should open with a GitHub URL pointing to that line using "main" as the ref

### Test 3: Multi-line Selection

1. Select multiple lines in a file
2. Run either of the permalink commands
3. The URL should include a line range (e.g., `#L10-L15`)

## Expected Behavior

### Success Cases
- Single line: URL includes `#L10` (example)
- Multiple lines: URL includes `#L10-L15` (example)
- Current SHA: URL includes the full commit hash
- Main branch: URL includes "main" instead of the commit hash

### Error Cases
- No file open: Shows error "No active editor found"
- Unsaved file: Shows error "The current file is not saved"
- Not in git repo: Shows error about git command failure
- No origin remote: Shows error about git command failure
- Non-GitHub remote: Shows error "The remote origin is not a GitHub URL"

## Keybindings (Optional)

You can add custom keybindings to your VS Code settings:

```json
{
    "key": "cmd+k cmd+g",
    "command": "turbocode.github.openPermalink"
},
{
    "key": "cmd+k cmd+m",
    "command": "turbocode.github.openPermalinkOnMain"
}
```

