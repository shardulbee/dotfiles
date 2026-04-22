---
name: jj
description: Complete jj version control reference. Use when you need the full cheat sheet, advanced revision syntax, or workflows beyond the concise summary in AGENTS.md.
---

# jj

## Mental Model

- **The working copy IS a commit (`@`).** Every file change automatically amends `@`. There is no staging area. No `add`, no `commit -a`. Just edit files and they're part of `@`.
- **`jj commit` = finalize `@` and start a new empty `@` on top.** It's like snapshotting the current state and moving on.
- **`jj new <rev>` = create a new empty `@` on top of `<rev>`.** This is how you "check out" a revision, start new work, or "stash" (via `jj new @-`).
- **Bookmarks (not branches).** jj has no "current branch" that auto-advances. You must explicitly `jj bookmark move` or `jj bookmark create`.
- **Conflicts can be committed.** No operation fails on conflict. No `--continue` flow. Resolve whenever, then `jj squash`.
- **`jj undo` reverts the last operation.** Safer than any reflog dance. Works on any operation.

## Cheat Sheet

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

## Revision Syntax

- `@` = current working-copy commit
- `@-` = parent of `@` (also `@--` for grandparent, etc.)
- `<rev>-` = parent(s) of rev, `<rev>+` = children
- `x::y` = x to y (ancestry path), `x..y` = ancestors of y not ancestors of x
- `trunk()` = main/master remote branch
- `bookmarks()` = all bookmark targets

## Tips

- `jj squash`, `jj split`, `jj commit`, `jj describe` all open an editor by default. Always pass `-m "message"` to avoid interactive editors.
- `jj split` is always interactive — avoid in automated contexts.
- After fetching, rebase onto upstream: `jj git fetch && jj rebase -b @ -o main`
- Use change IDs (left column in `jj log`) to refer to revisions — they stay stable across rewrites, unlike commit hashes.
