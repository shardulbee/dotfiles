# Coding Agent Configuration

### jj mental model (not git)

- **The working copy IS a commit (`@`).** Every file change automatically amends `@`. There is no staging area. No `add`, no `commit -a`. Just edit files and they're part of `@`.
- **`jj commit` = finalize `@` and start a new empty `@` on top.** It's like snapshotting the current state and moving on.
- **`jj new <rev>` = create a new empty `@` on top of `<rev>`.** This is how you "check out" a revision, start new work, or "stash" (via `jj new @-`).
- **Bookmarks (not branches).** jj has no "current branch" that auto-advances. You must explicitly `jj bookmark move` or `jj bookmark create`.
- **Conflicts can be committed.** No operation fails on conflict. No `--continue` flow. Resolve whenever, then `jj squash`.
- **`jj undo` reverts the last operation.** Safer than any reflog dance. Works on any operation.

### jj cheat sheet (git equivalents)

| Task | jj command |
|---|---|
| See status | `jj st` |
| See diff of current change | `jj diff` |
| See log | `jj log` |
| Finalize current work, start new change | `jj commit -m "msg"` |
| Edit description of `@` | `jj describe -m "msg"` |
| Edit description of any rev | `jj describe <rev> -m "msg"` |
| Start new work on top of a rev | `jj new <rev>` |
| Amend parent (like `git commit --amend`) | `jj squash` (moves `@` diff into `@-`) |
| Amend a specific ancestor | `jj squash --into <rev>` |
| Stash current work | `jj new @-` (old `@` stays as a sibling) |
| Unstash / return to a change | `jj edit <change-id>` |
| Merge two revisions | `jj new <rev-a> <rev-b>` |
| Rebase current stack onto main | `jj rebase -b @ -o main` |
| Rebase a commit + descendants | `jj rebase -s <rev> -o <dest>` |
| Cherry-pick a commit | `jj duplicate <rev> -o <dest>` |
| Abandon (delete) a commit | `jj abandon <rev>` |
| Discard all changes in `@` | `jj restore` |
| Discard changes in specific files | `jj restore <paths>...` |
| Revert a commit (create inverse) | `jj revert -r <rev> -B @` |
| Create a bookmark | `jj bookmark create <name> -r <rev>` |
| Move a bookmark | `jj bookmark move <name> --to <rev>` |
| List bookmarks | `jj bookmark list` |
| Fetch from remote | `jj git fetch` |
| Push a bookmark | `jj git push --bookmark <name>` |
| Push current change (auto-name) | `jj git push -c @` |
| Undo last operation | `jj undo` |

### jj revision syntax

- `@` = current working-copy commit
- `@-` = parent of `@` (also `@--` for grandparent, etc.)
- `<rev>-` = parent(s) of rev, `<rev>+` = children
- `x::y` = x to y (ancestry path), `x..y` = ancestors of y not ancestors of x
- `trunk()` = main/master remote branch
- `bookmarks()` = all bookmark targets

### jj tips

- `jj squash`, `jj split`, `jj commit`, `jj describe` all open an editor by default. Always pass `-m "message"` to avoid interactive editors.
- `jj split` is always interactive — avoid in automated contexts.
- After fetching, rebase onto upstream: `jj git fetch && jj rebase -b @ -o main`
- Use change IDs (left column in `jj log`) to refer to revisions — they stay stable across rewrites, unlike commit hashes.

**Use jj, not git.**

## Secrets

Never cat, echo, or otherwise print secrets (API keys, passwords, tokens, env files containing credentials) into the context window. Instead, reference them by path or variable name, and pipe them directly where needed (e.g., `source /path/to/env && command`).

## General Preferences

- Use `uv` instead of `pip` for Python package management
- Default to `bun` for JavaScript/TypeScript, but check project CLAUDE.md for overrides (some projects use pnpm or yarn)

## Web Search

- When you need to look something up on the web, use Codex web search: `codex --search exec --skip-git-repo-check --sandbox read-only "<question>. Use the web search tool. Search for the latest available information as of <early|mid|late> <year>. Do not execute commands or modify files. Return an answer with source URLs (if available)."`

## Approach

- Reason from first principles.
- Ignore "clean code" dogma and modern software engineering cargo cults.
- Aggressively minimize complexity.
- Be terse, brief, and simple.
- Design for testability using "functional core, imperative shell": keep pure business logic separate from code that does IO.

## MCP

Use `mcporter` to interact with MCP servers. Examples:
- `mcporter list <server>` — list available tools
- `mcporter call <server>.<tool> key=value` — call a tool
- `mcporter auth <server>` — authenticate with an OAuth-protected server

## GitHub

Use the `gh` CLI. Use `--repo owner/repo` when not in a git directory. Use `--json` and `--jq` for structured output. Use `gh api` for anything not covered by subcommands.
