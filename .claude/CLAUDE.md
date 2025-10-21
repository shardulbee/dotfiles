# Claude Configuration

## Version Control - CRITICAL

**ALWAYS USE JJ (Jujutsu) INSTEAD OF GIT**

## Core Concepts

- `@` = current working copy, `@-` = parent
- Working copy is automatically a commit (no staging area)
- Bookmarks = named pointers (like git branches)

## Essential Commands

```shell
# View
jj log                           # Show history
jj st                            # Status
jj diff [-r <commit>]           # Show changes

# Commit
jj commit [-m "msg"]            # Commit working copy, create new empty working copy
jj describe -m "msg"            # Just add description

# Split commits by file
jj split -r <commit> 'file:"path/to/file"'           # Split specific files
jj split                                              # Split working copy

# Move files between commits
jj restore -c <commit> 'file:"path"'                 # Move file from @ to commit
jj squash                                             # Move @ into parent
jj squash --from <src> --into <dest> 'file:"path"'  # Move specific files

# Bookmarks
jj bookmark move --from 'heads(::@- & bookmarks())' --to @-  # Move bookmark forward
jj bookmark create <name> -r @                        # Create bookmark
jj bookmark delete <name>                             # Delete bookmark

# Rebase
jj rebase -b 'heads(mine() & mutable())' -d main@origin  # Sync all work with main
jj rebase -r <commit> -d <target>                         # Rebase single commit

# Clean up
jj abandon -r '~mine() & mutable()'        # Remove non-yours commits
jj abandon --retain-bookmarks -r <commit>  # Remove commit, keep bookmarks
jj new -r <commit>                         # Create new working copy at commit

# Git sync
jj git fetch                        # Fetch from remotes
jj git push --all                   # Push all bookmarks
jj git push --change <change-id>    # Push with auto-generated bookmark
jj git push --bookmark <name>       # Push specific bookmark
jj git push --deleted               # Delete remote bookmarks

# Undo
jj undo                  # Undo last operation
jj op log               # View operation history
jj op restore <op-id>   # Restore to specific operation
```

## Common Workflows

```shell
# Standard commit & push flow
jj commit
jj bookmark move --from 'heads(::@- & bookmarks())' --to @-
jj git push --all

# Sync with main
jj git fetch
jj rebase -b 'heads(mine() & mutable())' -d main@origin
jj abandon -r '~mine() & mutable()'
jj git push --all

# Push single change
jj git push --change <change-id>
```

## Useful Revsets

```shell
@                       # Working copy
@-                      # Parent
mine()                  # Your commits
mutable()               # Non-immutable commits
remote_bookmarks()      # Remote bookmarks
bookmarks()             # Local bookmarks
heads(x)                # Heads in set x
```

## General Preferences

- No comments in code unless explicitly requested
- Use clean, standard commit messages
- When unsure: https://jj-vcs.github.io/jj/latest/
