# proj-init

Claude Code skill for initializing new project repos with standardized configuration.

## What This Is

A self-contained skill directory. Clone to `~/.claude/skills/proj-init/` and invoke with `/proj-init`.

## Structure

- `proj-init.md` -- Skill definition (the brain)
- `defaults.conf` -- User defaults for prompts
- `templates/` -- All file templates, organized by type
- `plugins/` -- Optional add-on modules (docker, CI, etc.)

## Templates

Templates use `{{PLACEHOLDER}}` syntax. The skill reads them at runtime, replaces placeholders with user-provided values, and writes the output files.

## Adding a New Project Type

1. Add `templates/gitignore/<type>.gitignore`
2. Add `templates/claude-md/<type>.md`
3. Add `templates/package-json/<type>.json`
4. Add `templates/tsconfig/<type>.json`
5. Add `templates/scaffolds/<type>.txt`
6. Update `proj-init.md` to include the new type in the selection prompt

## Adding a Plugin

Drop a new `.md` file in `plugins/`. The skill auto-discovers it. Follow the format of existing plugins.
