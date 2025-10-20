# Claude Configuration

## Version Control - CRITICAL

**ALWAYS USE JJ (Jujutsu) INSTEAD OF GIT**
- NEVER use git commands directly
- All version control operations must use jj
- If you're not confident about a jj command, consult the jj documentation at https://jj-vcs.github.io/jj/latest/
- Use revsets for precise revision selection: https://jj-vcs.github.io/jj/latest/revsets/

## Commit Guidelines

Use clean, standard commit messages following project conventions.

## General Preferences

- No comments in code unless explicitly requested
- When unsure about jj operations, refer to documentation rather than guessing

## Useful JJ Tips

- Use `--ignore-immutable` to rewrite immutable commits when necessary
- Remember that `@` refers to the current working copy revision
- Use `@-` to refer to the parent of the current revision
- Bookmarks in jj are similar to git branches but more flexible
