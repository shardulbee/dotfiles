# JJ Log View Implementation - Current State & Testing Plan

## Current Problem

The JJ log view extension is partially implemented but has a critical parsing issue preventing commits from being displayed and actions from working.

### Core Issue
**Commits are not being parsed from JJ log output** - the parser returns 0 commits even though the JJ command returns valid output.

### Current Architecture

1. **Virtual Document Provider** (`jjLogProvider.ts`)
   - Implements `vscode.TextDocumentContentProvider` for `jj://log/log` URI
   - Provides content by running `jj log` command and rendering it
   - Maintains line-to-commit mappings for actions
   - Supports expand/collapse of commit details

2. **JJ Utilities** (`jjUtils.ts`)
   - `execJj()` - Executes JJ commands, uses workspace root as working directory
   - `getJjRepoRoot()` - Finds JJ repository root using `jj root`
   - `parseLogOutput()` - **CURRENTLY BROKEN** - Should parse commit info from log output
   - `getLogCommand()` - Generates `jj log` command with template for parsing
   - `getCommitDetails()` - Fetches detailed commit info for expansion
   - `parseAnsiCodes()` - Parses ANSI escape codes for VS Code decorations

3. **Extension Commands** (`extension.ts`)
   - `jj.log.open` - Opens the log view
   - `jj.log.toggleExpand` - Toggles commit expansion (keybinding: `g e` or `Ctrl+E`)
   - `jj.log.edit`, `jj.log.describe`, `jj.log.rebase`, etc. - Various commit actions
   - All keybindings use `g` prefix to avoid vim conflicts

### Current Parsing Problem

**Template Format**: We're using a space-separated template:
```bash
jj log -n 100 --color=always -T 'commit_id.short() ++ " " ++ change_id.shortest(12) ++ " " ++ bookmarks.map(|b| b.name()).join(" ") ++ " " ++ description.first_line()'
```

**Output Format**: The template appends space-separated values to the graph:
```
@  266190423fe6 ppnyxztprttn push-ppnyxztprttn Purge gcloud cached credentials
│ ◆  3cc79f850b5d zlystqzlulpw cursor/include-environment-id-in-typedocs-error-logs-57fe cursor/include-environment-id-in-typedocs-error-logs-a053 cursor/include-environment-id-in-typedocs-error-logs-cba6 main Merge pull request #1240...
```

**Parser Issue**: The current parser (`parseLogOutput()`) looks for a 12-character hex commit ID and tries to parse tokens after it, but:
- The logic for extracting change_id, bookmarks, and summary is complex and error-prone
- Space-separated parsing is fragile (bookmarks can contain spaces, summaries are multi-word)
- The parser returns 0 commits even with valid output

### What Works
- ✅ Extension activation
- ✅ Workspace detection (uses VS Code workspace root)
- ✅ JJ command execution (commands run successfully)
- ✅ ANSI code stripping
- ✅ Virtual document provider registration
- ✅ Keybindings registered (vim-safe with `g` prefix)
- ✅ Output channel for debugging

### What Doesn't Work
- ❌ Commit parsing (returns 0 commits)
- ❌ Line-to-commit mappings (empty because no commits parsed)
- ❌ Toggle expand (fails because no commits found)
- ❌ All commit actions (depend on commit selection)
- ❌ Display formatting (doesn't match normal `jj log` format)

### Desired Behavior

**Display Format**: Should match normal `jj log` output:
```
@  ppnyxztp shardul@baral.ca 2025-11-05 13:42:18 push-ppnyxztprttn 26619042
│  Purge gcloud cached credentials
│ ◆  zlystqzl kirin@gadget.dev 2025-11-05 12:12:09 cursor/include-environment-id-in-typedocs-error-logs-57fe@origin ... 3cc79f85
╭─┤  (empty) Merge pull request #1240...
│ ~  (elided revisions)
├─╯
```

**Actions**: All should work on the commit at cursor:
- `g e` - Toggle expand/collapse commit details
- `g c` - Edit/checkout commit
- `g d` - Describe (edit commit message)
- `g r` - Rebase commit
- `g s` - Squash into current
- `g a` - Abandon commit
- `g p` - Open patch
- `g b` - Bookmark actions
- `g f` - Fetch
- `g P` - Push bookmark
- `g R` - Refresh

## Testing Requirements

### 1. JJ Command Execution Tests

**Test Cases Needed:**
- `execJj()` uses correct working directory (workspace root)
- `execJj()` handles errors correctly (shows stderr in error message)
- `getJjRepoRoot()` finds repo root from workspace directory
- `getJjRepoRoot()` throws appropriate error when not in JJ repo
- `isJjRepository()` correctly detects JJ repos

**Test Data:**
- Mock workspace root: `/Users/shardul/Documents/global-infrastructure`
- Mock `jj root` output: `/Users/shardul/Documents/global-infrastructure`
- Mock `jj log` output (see below)

### 2. Log Output Parsing Tests

**Test Cases Needed:**
- Parse single commit line with all fields
- Parse commit line with no bookmarks
- Parse commit line with multiple bookmarks (space-separated)
- Parse commit line with multi-word summary
- Parse commit line with graph characters before commit ID
- Handle lines without commits (graph-only lines like `│ ~`)
- Handle "elided revisions" lines
- Extract commit ID correctly from various graph formats (`@`, `◆`, `│ ◆`, etc.)

**Test Data - Sample JJ Log Output:**
```
@  266190423fe6 ppnyxztprttn push-ppnyxztprttn Purge gcloud cached credentials
│ ◆  3cc79f850b5d zlystqzlulpw cursor/include-environment-id-in-typedocs-error-logs-57fe cursor/include-environment-id-in-typedocs-error-logs-a053 cursor/include-environment-id-in-typedocs-error-logs-cba6 main Merge pull request #1240 from gadget-inc/kirin/scaledown_core_control_plane_15
╭─┤
│ ~  (elided revisions)
├─╯
◆    e4e326bcbeef zlqrvkxtqtmq  Merge pull request #1235 from gadget-inc/kirin/GGT-9234/use_alloydb_for_dateilager_pgbouncers
├─╮
│ ◆  fd93c374a0d4 vpsvzlxnnzyt  use alloydb as destination database for dateilager
│ │
│ ~
│
◆  4108eb0c60d2 rzqsqvnyzvmx  Raise gubernator presleep duration to see if errors in service discovery go away
│
~
```

**Expected Parse Results:**
- Line 0: `{commitId: "266190423fe6", changeId: "ppnyxztprttn", bookmarks: ["push-ppnyxztprttn"], summary: "Purge gcloud cached credentials"}`
- Line 1: `{commitId: "3cc79f850b5d", changeId: "zlystqzlulpw", bookmarks: ["cursor/include-environment-id-in-typedocs-error-logs-57fe", "cursor/include-environment-id-in-typedocs-error-logs-a053", "cursor/include-environment-id-in-typedocs-error-logs-cba6", "main"], summary: "Merge pull request #1240..."}`
- Lines 2-4: Should be skipped (no commits)
- Line 5: `{commitId: "e4e326bcbeef", changeId: "zlqrvkxtqtmq", bookmarks: [], summary: "Merge pull request #1235..."}`

### 3. Mutable Command Tests

**Test Cases Needed:**
- `jj edit -r <id>` - Verify working copy changes to specified commit
- `jj describe -r <id> -m <msg>` - Verify commit message updates
- `jj rebase -r <id> -d <dest>` - Verify commit moves to new parent
- `jj squash -r <id> -d @` - Verify commit squashed into current
- `jj abandon <id>` - Verify commit is abandoned
- `jj bookmark set <name> -r <id>` - Verify bookmark created/moved
- `jj bookmark rename <old> <new>` - Verify bookmark renamed
- `jj bookmark delete <name>` - Verify bookmark deleted
- `jj git fetch` - Verify remote refs updated
- `jj git push -b <name>` - Verify bookmark pushed

**Test Approach:**
- Use a test JJ repository (can be created with `jj init`)
- Run commands and verify state with `jj log`, `jj st`, `jj bookmark list`
- Clean up after each test (restore original state)

### 4. Display Formatting Tests

**Test Cases Needed:**
- Graph lines display correctly (preserve graph structure)
- Commit descriptions appear on next line with proper indentation
- ANSI codes are stripped but colors applied via decorations
- Expanded commits show details correctly
- Line mappings are correct (commit line numbers match display)

### 5. Integration Tests

**Test Cases Needed:**
- Opening log view works
- Toggle expand works when cursor on commit line
- Toggle expand works when cursor on description line (finds parent commit)
- All actions work when commit is selected
- Refresh preserves cursor position
- Refresh preserves expanded state

## Key Files

- `turbocode/src/jjUtils.ts` - Core JJ command execution and parsing
- `turbocode/src/jjLogProvider.ts` - Virtual document provider and display logic
- `turbocode/src/extension.ts` - Command registration and keybindings
- `turbocode/package.json` - Extension manifest with commands and keybindings

## Current Template Format

```bash
jj log -n 100 --color=always -T 'commit_id.short() ++ " " ++ change_id.shortest(12) ++ " " ++ bookmarks.map(|b| b.name()).join(" ") ++ " " ++ description.first_line()'
```

This appends space-separated values to each graph line. The parser needs to extract:
1. Commit ID (12-char hex) - anchor point
2. Change ID (12-char hex) - next token
3. Bookmarks (space-separated, variable count) - middle tokens
4. Summary (everything else) - last token(s)

## Alternative Approaches to Consider

1. **Use tab-separated template** - More reliable parsing, but breaks graph format
2. **Run `jj log` twice** - Once for display (no template), once for parsing (with template)
3. **Parse normal `jj log` output** - More complex but preserves original format
4. **Use JJ's JSON output** - `jj log --template json` for reliable parsing

## Next Steps

1. Write comprehensive tests for `parseLogOutput()` with various input formats
2. Fix parser to handle space-separated template format correctly
3. Write tests for mutable commands (use test repo)
4. Write integration tests for the full flow
5. Fix display formatting to match normal `jj log` output

