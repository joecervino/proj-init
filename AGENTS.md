# Repository Guidelines

## What This Is

`proj-init` is a Claude Code skill (markdown + templates, no build step). It initializes new project repos or augments existing ones with standardized config. The "brain" is `SKILL.md`; everything else is data it reads at runtime.

## Project Structure

- `SKILL.md` -- the skill definition. All workflow logic lives here.
- `defaults.conf` -- shell-style defaults (region, account, plugins) sourced at runtime.
- `templates/` -- file templates grouped by type. Subdirs: `gitignore/`, `claude-md/`, `agents-md/`, `design-md/`, `package-json/`, `tsconfig/`, `vitest/`, `envrc/`, `env-example/`, `deploy/`, `claude-settings/`, `mcp-json/`, `scaffolds/`.
- `plugins/` -- optional add-on modules, one `.md` file per plugin. Auto-discovered by the skill.
- `README.md`, `CLAUDE.md` -- human and agent docs for this repo itself.

## Editing Rules

- **Templates use `{{PLACEHOLDER}}` syntax.** The skill replaces them at write time. Never hardcode user-specific values in templates.
- **Adding a new project type** requires matching files across `templates/gitignore/`, `templates/claude-md/`, `templates/package-json/`, `templates/tsconfig/`, `templates/scaffolds/`, plus an update to `SKILL.md`'s type selection prompt.
- **Adding a plugin** means dropping a new `.md` file in `plugins/`. Match the structure of existing plugins (see `plugins/graphify.md`).
- **Do not modify antidesign DESIGN.md content** when the skill copies it -- verbatim copy with a source header only.

## Augment Mode Safety

The skill has two modes: `new` (fresh project) and `augment` (existing repo). Augment mode must never destroy user content:

- Missing files -> create from template.
- Existing files -> merge strategy per file type (see `SKILL.md` Phase 4.2). Generally: append to `.gitignore`, deep-merge `.mcp.json` and `settings.local.json`, merge only `scripts` in `package.json`, skip existing `tsconfig.json`/`vitest.config.ts`.
- Generic GCP-table `CLAUDE.md` (the known anti-pattern) is the one file that may be replaced wholesale.

When editing `SKILL.md`, preserve these merge invariants.

## Testing Changes

There is no test runner. To validate a change:

1. Read through the relevant section of `SKILL.md` end-to-end.
2. Dry-run mentally against both a fresh `~/Projects/foo` and an existing repo with partial config.
3. Verify all `{{PLACEHOLDER}}` tokens in new/edited templates are documented in `SKILL.md` Phase 2.

## Commit Style

Recent commits use prefixes like `add:`, `feat:`, `fix:`, `update:`, `chore:`, `docs:`. Follow the same style. Keep subject lines under ~60 chars.
