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

- Prefer concise, functional code
- No comments in code unless explicitly requested
- Follow existing patterns and conventions in the codebase
- When unsure about jj operations, refer to documentation rather than guessing

## Useful JJ Tips

- Use `--ignore-immutable` to rewrite immutable commits when necessary
- Remember that `@` refers to the current working copy revision
- Use `@-` to refer to the parent of the current revision
- Bookmarks in jj are similar to git branches but more flexible

## Python Development

**ALWAYS USE UV FOR PYTHON TASKS**
- Use `uv` for all Python dependency management and virtual environments
- Never use pip, poetry, or pipenv directly
- When creating Python scripts, use inline script dependencies with uv's script metadata format:
  ```python
  #!/usr/bin/env -S uv run
  # /// script
  # dependencies = ["package1", "package2"]
  # ///
  ```
- This ensures reproducible, self-contained scripts without manual venv management

## Telegram Notifications

**OPPORTUNISTIC TASK COMPLETION NOTIFICATIONS**
- When working on long-running tasks (>5-10 minutes) or complex multi-step tasks, send a Telegram notification upon completion
- Use `~/bin/telegram-notify` to send notifications (e.g., `telegram-notify "Task completed: Built and deployed application"`)
- Good candidates for notifications:
  - Large codebase refactoring or migrations
  - Build/test/deployment processes that take significant time
  - Multi-step tasks with many todo items
  - Any task where the user might benefit from being notified when complete
- Keep notifications concise and informative about what was accomplished
- Only send completion notifications, not progress updates unless explicitly requested
