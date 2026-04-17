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
- **.devcontainer/devcontainer.json** -- per-repo dev container with repo-local `CLOUDSDK_CONFIG` plus isolated dependency volumes (`node_modules`, pnpm store)
- **.devcontainer/post-create.sh** -- initializes repo-local auth directories, auto-repairs `node_modules` and pnpm store permissions, falls back to repo-local store when needed, retries low-concurrency on install OOM, and auto-installs pnpm deps in-container (`--no-frozen-lockfile`)
- **scripts/dev-auth-ensure-sa.sh** -- idempotent one-time IAM prep (SA create/check, TokenCreator grant, optional SA project roles, bootstrap command output)
- **scripts/dev-auth-bootstrap.sh** -- bootstrap auth with impersonation default, WIF fallback, key last resort
- **scripts/dev-auth-doctor.sh** -- validates CLI and ADC auth separately
- **scripts/dev-auth-reset.sh** -- clears only repo-local auth state
- **docs/local-dev-gcp.md** -- concise local setup and validation flow
- **.mcp.json** -- claude-flow v3 MCP server configuration
- **scripts/deploy.sh** -- Deploy script with GCP project guard
- **package.json, tsconfig.json, vitest.config.ts** -- TypeScript project config
- Optimized folder structure based on project type

## GCP Devcontainer auth model

- `CLOUDSDK_CONFIG` is repo-local: `.devcontainer/.state/gcloud`
- Node deps are isolated in container volumes (`node_modules`, `/home/node/.pnpm-store`) to prevent host/container native binary collisions
- post-create self-heals unwritable `node_modules` and pnpm-store volumes (`sudo chown`), and falls back to `.devcontainer/.state/pnpm-store` if store repair fails
- if install is killed by container memory pressure (exit 137), post-create retries once with reduced pnpm concurrency
- one-time IAM prep command: `./scripts/dev-auth-ensure-sa.sh --project <id> --me <you@example.com>`
- auth helpers use this priority: impersonation -> WIF -> key (last resort)
- helper metadata is stored under `.devcontainer/.auth` (gitignored)
- optional local credential scratch files go under `.devcontainer/.secrets` (gitignored)
- no secrets or service-account keys are committed

## Devcontainer extension bundles

- Devcontainers use a lean baseline extension set and optional bundles.
- New project default: `gcp` bundle enabled, all others off by default.
- Augment mode: bundle defaults are inferred from repo signals, then user can override.
- Supported bundles: `gcp`, `aws`, `terraform`, `jupyter`, `mermaid`, `n8n`, `neon`, `figma`.
- AWS selection only changes extension install, not auth/deploy scaffolding.
- Permanently excluded from auto-install: Code Spell Checker, Color Picker, Color Highlight, JavaScript Snippets, Quokka, Quokka status bar, SCSS IntelliSense, Tailwind IntelliSense.

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
