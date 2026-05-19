# Agent Configuration

## Hard Rules

- Default to short, high-information-density answers. Expand only when detail changes the decision.
- No filler, repetition, generic advice, or unnecessary caveats.
- Reason from first principles.
- Value Pareto efficiency and simplicity.
- Aggressively minimize complexity; question whether every abstraction, tool, step, or recommendation needs to exist.
- Do not default to conventional "best practices" unless they clearly improve the outcome.
- Ignore "clean code" dogma and modern software engineering cargo cults.
- Design for testability using "functional core, imperative shell": keep pure business logic separate from code that does IO.
- Always use jj. Never run any git command.
- Never cat, echo, or print secrets. Reference them by path or variable name only.
- Always use uv for Python. Never use pip.
- Always pass `-m "msg"` to `jj commit`, `jj describe`, and `jj squash`. They open an editor by default - the agent cannot interact with it.
- Never use `jj split` in automated contexts. It is always interactive.

## Defaults

- JS/TS: use npm.
- GitHub: use `gh` CLI. Use `--repo owner/repo` outside git dirs. Use `--json` and `--jq` for structured output. `gh api` for anything not covered by subcommands.

## jj

The working copy IS a commit (`@`). Every change auto-amends `@`. No staging area.

Common commands:
- `jj st` / `jj diff` / `jj log`
- `jj commit -m "msg"` - finalize `@`, start new empty `@` on top
- `jj new <rev>` - checkout / start work on `<rev>`
- `jj squash -m "msg"` - amend `@-` with current changes
- `jj restore` - discard all changes in `@`
- `jj bookmark create <name> -r <rev>` / `jj bookmark move <name> --to <rev>` / `jj bookmark list`
- `jj tug` - move closest bookmark from `@-` to `@` (alias: `bookmark move --from closest_bookmark(@-) --to @-`)
- `jj rebase -b @ -o main` - rebase onto main
- `jj undo` - revert last operation

After fetching: `jj git fetch && jj rebase -b @ -o main`

Syntax: `@` = current, `@-` = parent, `trunk()` = main/master.

Full reference: `/skill:jj`
