# Agent Configuration

## Operating Rules

- Be brief, high-signal, and specific. Expand only when detail changes the
  decision.
- Avoid filler, repetition, generic advice, and unnecessary caveats.
- Reason from first principles.
- Use 80/20 + YAGNI: choose the smallest sufficient solution; do not add
  future-proofing, abstraction, config, dependency, or generality unless the
  current task needs it.
- Ignore cargo-cult “best practices.” Use a practice only when it improves this
  specific outcome.

## Code

- Minimize complexity. Question every abstraction, helper, layer, tool, and
  step.
- Prefer functional core, imperative shell: pure logic inside; IO, mutation, and
  orchestration outside.
- Prefer visible, linear code for one-off stateful workflows.
- Inline helpers when a function boundary hides execution order, mutation, cost,
  or dependencies.
- Extract functions only when they are reused, clarify the caller, or isolate
  pure logic.
- Treat hidden mutable state as the main enemy; keep state transitions local and
  obvious.
- Keep execution order, branching, and cost obvious in hot or
  correctness-sensitive paths.
- Avoid copy-paste-modify. Use loops, tables, or data-driven structure for
  regular repetition.

## Tools

- Use `jj`; never invoke `git`. `jj git ...` is allowed.
- Use `uv` for Python; never use `pip`.
- Use `npm` for JS/TS.
- Use `gh` for GitHub. Outside repo dirs, pass `--repo owner/repo`; prefer
  `--json` and `--jq`; use `gh api` when subcommands are insufficient.
- Never print secrets. Reference them only by path or variable name.

## jj

- `@` is the working-copy commit; changes auto-amend it. There is no staging
  area.
- If `@` is a single working-copy commit with multiple parents/bookmark heads,
  assume the user is likely using a megamerge workflow. Do not push the
  megamerge. Move the current changes into the intended branch with
  `jj squash --into <rev> -m "msg"`, or split/rebase a new commit onto the
  correct branch if the changes do not belong in an existing commit.
- Always pass `-m "msg"` to `jj commit`, `jj describe`, and `jj squash`.
- Never use `jj split` in automation; it is interactive.
- After fetching: `jj git fetch && jj rebase -b @ -o main`.
- Common commands: `jj st`, `jj diff`, `jj log`, `jj commit -m "msg"`, `jj new
  <rev>`, `jj squash -m "msg"`, `jj restore`, `jj undo`, `jj tug`.

Revision syntax: `@` = current, `@-` = parent, `trunk()` = main/master.

Full reference: `/skill:jj`
