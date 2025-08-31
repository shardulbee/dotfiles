# Generate Commit and Push

Create a commit with an appropriate message and push changes using jj workflow.

## Usage

```
/gencommit new              # Create commit and push as anonymous branch (no bookmark)
/gencommit new <name>       # Create commit with named bookmark and push
/gencommit tug              # Create commit and tug closest ancestor bookmark forward
/gencommit main             # Create commit and advance main bookmark
```

**CRITICAL**. If a mode is not provided, exit early BEFORE RUNNING ANYTHING ELSE, telling the user that an explicit mode must be provided.

## Workflow Overview

1. Check if @ is empty → Exit if no changes
2. Analyze all changes → Generate commit message
3. Create commit → Use appropriate jj command
4. Execute mode → new/tug/main specific behavior
5. Push changes → Verify success

## Instructions

### 1. Mode Validation

Validate arguments before proceeding:
- Valid modes: "new", "tug", "main"
- "new" can have optional bookmark name
- Other modes cannot have additional arguments
- Show usage help for invalid modes

### 2. Pre-commit Checklist

**Run these commands IN PARALLEL** to gather context efficiently:
```bash
# PARALLEL EXECUTION - Run all these commands simultaneously:
# 1. Check if there are any changes to commit
jj log -r @ --no-pager --no-graph -T 'if(empty, "empty", "not empty") ++ "\n"'

# 2. Show current bookmark context
jj log --no-pager -r  "@ | ancestors(@, 10)" --no-graph -T 'separate(" | ",
  change_id.short(),
  if(bookmarks, bookmarks.join(",")),
  if(description, description.first_line(), "**NO DESCRIPTION**"),
) ++ "\n"'
```

**After parallel execution, analyze results:**
- If the first command output is "empty", stop with message: "No changes to commit - working copy is empty"
- If any changesets show "**NO DESCRIPTION**", note which ones lack descriptions

### 3. Analyze Changes

**Run these analysis commands IN PARALLEL**:
```bash
# PARALLEL EXECUTION - Run simultaneously for comprehensive analysis:
# 1. See which files are modified
jj status --no-pager

# 2. Read ALL modified files shown in jj status output IN PARALLEL
# For each file path shown in jj status, run: jj diff <filepath>
```

**IMPORTANT**: Read every modified file's diff in parallel to understand the full scope of changes. This will help generate an accurate and comprehensive commit message.

### 4. Creating the Commit

After analyzing all changes, create a single commit with a well-crafted message:

```bash
jj commit -m "<your generated message>"
```

### 5. Execute Mode-Specific Workflow

After creating the commit, execute the appropriate mode:

a) **Mode: new** (Push as anonymous branch):
   ```bash
   jj git push -r @-
   ```

b) **Mode: new <name>** (Named bookmark):
   ```bash
   # Create bookmark at the last commit
   jj bookmark create <name> -r @-
   
   # Push the bookmark
   jj git push --bookmark <name>
   ```

c) **Mode: tug** (Tug closest bookmark):
   ```bash
   jj tug && jj git push -r @-
   ```

d) **Mode: main** (Advance main):
   ```bash
   jj bookmark move main --to @- && jj git push -r @-
   ```

## Commit Message Guidelines

**CRITICAL: DO NOT USE SEMANTIC COMMIT FORMAT**
- No prefixes like "feat:", "fix:", "chore:", etc.
- Write natural, descriptive messages

### Format
- First line: Max 72 characters, summary of changes
- If needed: Blank line, then more details in subsequent lines
- Keep additional lines terse but informative
- Focus on what changed and why, not how

### Examples of Good Messages
```
Update Ghostty config with new keybindings and color scheme

Reorganize Neovim plugin configuration for better performance
- Lazy load heavy plugins
- Optimize startup sequence
- Remove unused configurations

Fix shell completion issues in fish config
```

### Examples to Avoid
```
feat: add new feature     ❌ (semantic commit)
Updated files             ❌ (too vague)
Changes                   ❌ (meaningless)
fix: bug                  ❌ (semantic commit + vague)
```

## Error Handling

### Common Errors and Solutions

1. **"Immutable commit" error**: Add `--ignore-immutable` flag to the command
2. **"Bookmark already exists" error**: Use `jj bookmark move` instead of `create`
3. **"Push rejected" error**: Run `jj git fetch` then retry the push
4. **Network/connection errors**: Inform user and suggest retrying
5. **Empty working copy after creating commits**: This is EXPECTED - all changes were successfully committed

### If ANY command fails:
- Show the exact error message to the user
- Do NOT proceed with subsequent commands
- Ask for user guidance on how to proceed

## Working Copy State

- After `jj commit`: @ becomes new empty changeset (NORMAL)
- After `jj squash`: specified files removed from @
- Empty @ after commits means SUCCESS
- Never create commits for empty working copy

## Quick JJ Reference

- `@`: Current working copy
- `@-`: Parent of working copy (the last commit)
- `jj new -B @`: Create new commit BEFORE current @ (between @- and @)
- `jj squash --from @ --to @-`: Move changes to parent
- `jj commit`: Finalize @ with message, create new empty @
- `jj tug`: Custom alias that finds nearest ancestor bookmark and moves it to @-

## Push Command Reference

- `jj git push -r @-`: Pushes the revision @- (last commit) as an anonymous branch
- `jj git push --bookmark <name>`: Pushes a specific named bookmark
- Both commands push to the default remote (usually 'origin')
- The `-r` flag specifies a revision, while `--bookmark` specifies a bookmark name

## Important Notes

- **IMPORTANT**: If the user does not provide any arguments, display this error and exit:
  ```
  Error: No mode specified. Please use one of:
  - /gencommit new              # Push as anonymous branch
  - /gencommit new <name>       # Create named bookmark and push
  - /gencommit tug              # Tug closest bookmark forward
  - /gencommit main             # Advance main bookmark
  ```
- **CRITICAL**: Always use jj for version control, never git
- You can use --ignore-immutable to rewrite immutable commits if needed

## Arguments

$ARGUMENTS