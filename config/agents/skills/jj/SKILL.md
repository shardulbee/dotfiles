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
- **A multi-parent `@` is often a megamerge workspace.** If the working-copy commit has multiple parents/bookmark heads, assume the user may be composing several PRs locally. Do not push the megamerge itself unless explicitly asked. Move edits from `@` into the right branch commit with `jj squash --into <rev>`, or make a new commit and rebase it onto the right branch.

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
| Move megamerge WIP into one branch | `jj squash --into <bookmark-or-change> -m "msg"` |
| Make megamerge WIP a new branch commit | `jj commit -m "msg"` then rebase the new change with `jj rebase -r <rev> --after <branch-tip>` |
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

## Aliases

Add these to `~/.jjconfig.toml` or `.jj/config.toml`:

```toml
[revset-aliases]
'closest_bookmark(to)' = 'heads(::to & bookmarks())'

[aliases]
# Move the closest bookmark to the current commit. Useful when working on a
# named bookmark, creating commits, and needing to update the bookmark before
# pushing.
tug = ["bookmark", "move", "--from", "closest_bookmark(@-)", "--to", "@-"]
```

## Tips

- `jj squash`, `jj split`, `jj commit`, `jj describe` all open an editor by default. Always pass `-m "message"` to avoid interactive editors.
- `jj split` is always interactive — avoid in automated contexts.
- After fetching, rebase onto upstream: `jj git fetch && jj rebase -b @ -o main`
- Use change IDs (left column in `jj log`) to refer to revisions — they stay stable across rewrites, unlike commit hashes.

## Megamerge Workflow

- A megamerge is a local merge commit whose parents are the branch tips the user wants in one working tree. It is a workspace, not the thing to submit.
- Common shape: `@` has multiple parents/bookmark heads and contains the live edits. Treat those edits as WIP that must be placed onto the correct branch before pushing.
- If all edits belong in an existing branch commit, run `jj squash --into <branch-change-or-bookmark> -m "msg"` so the branch/bookmark gets amended and `@` goes back to being an empty workspace.
- If the edits are a new logical commit, run `jj commit -m "msg"` to create it, then rebase that new change onto the correct branch, often with `jj rebase -r <rev> --after <branch-tip>` and `--before <megamerge>` when preserving the workspace shape matters.
- If one `@` contains changes for multiple branches, do not guess. In automation, avoid `jj split`; ask the user or use non-interactive path-limited `jj squash` only when the file ownership is obvious.

References:

- https://isaaccorbrey.com/notes/jujutsu-megamerges-for-fun-and-profit
- https://ofcr.se/jujutsu-merge-workflow
- https://v5.chriskrycho.com/journal/jujutsu-megamerges-and-jj-absorb/
- https://jonalmeida.com/til/jj-megamerge/
- https://andre.arko.net/2025/10/12/jj-part-3-workflows/
