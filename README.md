# proj-init

A Claude Code skill that initializes new projects or augments existing repos with standardized configuration, GCP isolation, and optimized folder structures.

## Two modes

- **New project** -- Creates a fresh repo from scratch with all config files
- **Augment existing repo** -- Scans an existing project, adds missing files, and intelligently merges improvements into existing ones (e.g., appending .gitignore entries, adding missing package.json scripts, merging MCP servers)

## What it creates / adds

- **CLAUDE.md** -- Project-specific instructions for Claude Code agents
- **AGENTS.md** -- Coding standards, commands, and conventions
- **DESIGN.md** -- Design system from [antidesign](https://github.com/anti-enterprises/antidesign) (54 curated brands) or skeleton
- **.envrc** -- direnv config for GCP project isolation
- **.mcp.json** -- claude-flow v3 MCP server configuration
- **scripts/deploy.sh** -- Deploy script with GCP project guard
- **package.json, tsconfig.json, vitest.config.ts** -- TypeScript project config
- Optimized folder structure based on project type

## Project types

| Type | Description |
|------|-------------|
| `nextjs` | Next.js App Router + Tailwind + Vitest |
| `monorepo` | pnpm workspaces with apps/ + packages/ |
| `cloud-functions` | GCP Cloud Functions + web frontend |
| `api-only` | Fastify API service |
| `minimal` | Bare TypeScript project |

## Installation

```bash
git clone git@github.com:<user>/proj-init.git ~/.claude/skills/proj-init
```

## Usage

In any Claude Code session:

```
/proj-init
```

## Configuration

Edit `defaults.conf` to set your common defaults (GCP region, account, etc.).

## Updating

```bash
cd ~/.claude/skills/proj-init && git pull
```

## Plugins

Built-in add-ons: `graphify`, `caveman`, `docker`, `ci-github-actions`, `ci-cloud-build`.

`graphify` and `caveman` are selected by default for new projects. Add your own by dropping a `.md` file in `plugins/`.
