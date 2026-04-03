---
name: proj-init
description: Initialize a new project with CLAUDE.md, AGENTS.md, DESIGN.md (from antidesign), direnv GCP isolation, ruflo/claude-flow config, deploy scripts, and optimized folder structure. Use when starting a new project repo.
---

# proj-init -- Project Initialization Skill

You are initializing a new project. Follow this workflow exactly.

## Setup

The skill directory is at `~/.claude/skills/proj-init/`. All templates are read from `~/.claude/skills/proj-init/templates/`. If the skill is symlinked from another location, resolve the symlink to find templates.

First, read the defaults file:

```
Read ~/.claude/skills/proj-init/defaults.conf
```

Parse the shell variables as defaults for the prompts below.

Then check if the antidesign repo is available:

```bash
ls ~/Projects/antidesign/design-md/ 2>/dev/null | head -5
```

Store whether the design repo is available (it should be). If missing, you'll fall back to the skeleton template.

## Phase 1: Gather Project Details

Use **AskUserQuestion** to collect all required information. Ask across multiple rounds to keep it manageable.

### Round 1: Identity & GCP

Ask these 4 questions simultaneously:

1. **Project name** (header: "Name")
   - Options: Free text input
   - Validation: must match `^[a-z][a-z0-9-]*$` (kebab-case, starts with letter)
   - The directory `~/Projects/<name>` must NOT already exist

2. **Project description** (header: "Description")
   - Options: Free text input (one sentence)

3. **GCP account email** (header: "GCP Account")
   - Default from `DEFAULT_ACCOUNT` in defaults.conf
   - Options: Show default if set, plus "Other" for custom input

4. **GCP project ID** (header: "GCP Project")
   - Options: Free text input
   - Validation: must match `^[a-z][a-z0-9-]{4,28}[a-z0-9]$`

### Round 2: Type & Options

Ask these 3 questions simultaneously:

1. **Project type** (header: "Type")
   - Options: nextjs, monorepo, cloud-functions, api-only, minimal
   - nextjs = Next.js full-stack (App Router, Tailwind, Vitest)
   - monorepo = pnpm workspaces (apps/ + packages/)
   - cloud-functions = GCP Cloud Functions + web frontend
   - api-only = Fastify API service
   - minimal = Bare TypeScript project

2. **GCP region** (header: "Region")
   - Default from `DEFAULT_REGION` in defaults.conf
   - Options: us-central1, us-west1, us-east1, australia-southeast1

3. **Dev/prod environment switching?** (header: "Dev/Prod")
   - Options: No (single environment), Yes (creates dev config + conditional .envrc)
   - If yes, follow up asking for dev project ID and dev config name

### Round 3: Design System Selection

**This round selects a production-grade DESIGN.md from the antidesign collection.** The repo at `~/Projects/antidesign/design-md/` contains 54 curated design systems from real brands. Ask two questions to narrow down the right one.

If the antidesign repo is NOT available, skip this round and use the skeleton template at `templates/design-md/standard.md` instead.

#### Question 1: Target market & industry (header: "Market")

Ask: "What market or industry is this project targeting?"

Options:
- **Developer tools & APIs** -- SaaS for developers, CLIs, platforms, integrations
- **AI & Machine learning** -- AI products, model APIs, ML infrastructure
- **Fintech & Payments** -- Banking, crypto, payments, financial services
- **Consumer & Marketplace** -- Consumer apps, marketplaces, media, social
- **Enterprise & B2B** -- Enterprise software, infrastructure, cloud services

#### Question 2: Visual aesthetic (header: "Aesthetic")

Ask: "What visual style fits this project?"

Options (show preview descriptions to help the user choose):
- **Minimal & typography-first** -- Clean whitespace, tight letter-spacing, type carries the design. Feels precise and modern.
- **Warm & approachable** -- Organic shapes, warm colors, generous spacing. Feels human and inviting.
- **Bold & dark-native** -- Dark backgrounds, high contrast, vivid accents. Feels technical and powerful.
- **Clean & precise** -- Balanced layouts, neutral palette, systematic spacing. Feels polished and professional.

#### Recommend & Select Design System (header: "Design")

Based on the market + aesthetic answers, use the mapping table below to select the top 3 recommended brands. Then ask the user to pick one:

**DESIGN RECOMMENDATION MAP:**

| Market | Minimal & typography | Warm & approachable | Bold & dark-native | Clean & precise |
|--------|---------------------|--------------------|--------------------|-----------------|
| Developer tools | vercel, linear.app, resend | notion, mintlify, intercom | cursor, supabase, warp | figma, expo, stripe |
| AI & ML | vercel, linear.app, opencode.ai | claude, cohere, ollama | mistral.ai, x.ai, elevenlabs | replicate, together.ai, runwayml |
| Fintech | stripe, wise, revolut | revolut, wise, intercom | kraken, coinbase, kraken | stripe, wise, coinbase |
| Consumer | uber, pinterest, airbnb | airbnb, spotify, pinterest | spotify, bmw, spacex | apple, pinterest, uber |
| Enterprise | hashicorp, mongodb, sanity | intercom, airtable, miro | nvidia, spacex, clickhouse | ibm, apple, hashicorp |

Ask: "Which design system should we use? (Recommended based on your market + aesthetic)"

Show the 3 recommended brands as options with brief descriptions. Read the first ~5 lines of each brand's DESIGN.md to extract the visual theme description for the option preview. For example:

```
Read ~/Projects/antidesign/design-md/vercel/DESIGN.md (limit: 20 lines)
```

Include a 4th option: **"Blank skeleton"** -- Start with an empty DESIGN.md template to fill in manually or via `/design-consultation`.

If the user picks "Other", ask them to name a specific brand from the antidesign collection (list all 54 as a hint).

Store the selected brand name (e.g., `vercel`, `claude`, `stripe`) or `skeleton` as the `DESIGN_SOURCE` variable.

### Round 4: Plugins (optional)

Ask one multi-select question:

1. **Optional plugins** (header: "Plugins", multiSelect: true)
   - docker: Dockerfile + docker-compose.yml + .dockerignore
   - ci-github-actions: .github/workflows/ CI pipeline
   - ci-cloud-build: cloudbuild.yaml for GCP Cloud Build
   - None: skip plugins

## Phase 2: Derive Variables

From the gathered inputs, compute these template variables:

| Variable | Value |
|----------|-------|
| `{{PROJECT_NAME}}` | The kebab-case project name |
| `{{PROJECT_DESCRIPTION}}` | The one-sentence description |
| `{{GCP_CONFIG_NAME}}` | Same as project name (unless user overrides) |
| `{{GCP_ACCOUNT_EMAIL}}` | The GCP account email |
| `{{GCP_PROJECT_ID}}` | The GCP project ID |
| `{{GCP_REGION}}` | The selected region |
| `{{PROJECT_DIR}}` | `~/Projects/{{PROJECT_NAME}}` |
| `{{PROJECT_NAME_UPPER}}` | Uppercase with underscores (for env var prefix in devprod) |
| `{{GCP_CONFIG_NAME_DEV}}` | `{{GCP_CONFIG_NAME}}-dev` (if devprod) |
| `{{GCP_PROJECT_ID_DEV}}` | The dev project ID (if devprod) |
| `{{DEFAULT_PNPM_VERSION}}` | From defaults.conf |
| `{{DEFAULT_NODE_VERSION}}` | From defaults.conf |
| `DESIGN_SOURCE` | Brand name from antidesign (e.g., `vercel`) or `skeleton` |

## Phase 3: Show Summary & Confirm

Before creating anything, show a summary:

```
=== Project Summary ===
  Name:         {{PROJECT_NAME}}
  Description:  {{PROJECT_DESCRIPTION}}
  Directory:    ~/Projects/{{PROJECT_NAME}}
  Type:         <type>
  Design:       <brand name> (from antidesign) | blank skeleton
  GCP Config:   {{GCP_CONFIG_NAME}}
  GCP Account:  {{GCP_ACCOUNT_EMAIL}}
  GCP Project:  {{GCP_PROJECT_ID}}
  GCP Region:   {{GCP_REGION}}
  Dev/Prod:     yes/no
  Plugins:      <list or none>
```

Ask user to confirm with AskUserQuestion (Proceed? Yes / No / Edit details).

## Phase 4: Create Project

Execute these steps in order. For each file, read the template from the skill directory, replace all `{{PLACEHOLDERS}}`, and write to the project directory.

### 4.1 Create directory structure

Read the scaffold file: `~/.claude/skills/proj-init/templates/scaffolds/<type>.txt`

Each line is a directory path. Create all directories with `mkdir -p`.

### 4.2 Write core files

For each file below, read the template, replace placeholders, and write. **Never overwrite an existing file.**

| Template | Output |
|----------|--------|
| `templates/gitignore/<type>.gitignore` | `{{PROJECT_DIR}}/.gitignore` |
| `templates/envrc/standard.envrc` (or `devprod.envrc` if dev/prod) | `{{PROJECT_DIR}}/.envrc` |
| `templates/env-example/standard.env` | `{{PROJECT_DIR}}/.env.example` |
| `templates/claude-md/<type>.md` | `{{PROJECT_DIR}}/CLAUDE.md` |
| `templates/agents-md/standard.md` | `{{PROJECT_DIR}}/AGENTS.md` |
| *See 4.3 for DESIGN.md* | `{{PROJECT_DIR}}/DESIGN.md` |
| `templates/mcp-json/standard.json` | `{{PROJECT_DIR}}/.mcp.json` |
| `templates/claude-settings/settings.local.json` | `{{PROJECT_DIR}}/.claude/settings.local.json` |
| `templates/package-json/<type>.json` | `{{PROJECT_DIR}}/package.json` |
| `templates/tsconfig/<type>.json` | `{{PROJECT_DIR}}/tsconfig.json` |
| `templates/vitest/standard.ts` | `{{PROJECT_DIR}}/vitest.config.ts` |
| `templates/deploy/deploy.sh` | `{{PROJECT_DIR}}/scripts/deploy.sh` |
| `templates/deploy/common.sh` | `{{PROJECT_DIR}}/scripts/lib/common.sh` |

After writing deploy.sh and common.sh, make them executable:
```bash
chmod +x {{PROJECT_DIR}}/scripts/deploy.sh
chmod +x {{PROJECT_DIR}}/scripts/lib/common.sh
```

For **monorepo** type, also create:
- `{{PROJECT_DIR}}/pnpm-workspace.yaml` with content:
  ```yaml
  packages:
    - 'apps/*'
    - 'packages/*'
  ```
- Sub-package `package.json` and `tsconfig.json` files for each app/package in the scaffold

For **cloud-functions** type, also create:
- `{{PROJECT_DIR}}/pnpm-workspace.yaml` with content:
  ```yaml
  packages:
    - 'functions'
    - 'web'
  ```

### 4.3 Write DESIGN.md (from antidesign or skeleton)

This step is separate because it has two sources:

**If `DESIGN_SOURCE` is a brand name** (not `skeleton`):

1. Read the full DESIGN.md from the antidesign repo:
   ```
   Read ~/Projects/antidesign/design-md/<DESIGN_SOURCE>/DESIGN.md
   ```

2. Write the contents directly to `{{PROJECT_DIR}}/DESIGN.md`. Do NOT modify the content -- these are curated design systems meant to be used as-is.

3. Add a header comment at the very top (before the existing content):
   ```markdown
   <!-- Design system sourced from antidesign/<DESIGN_SOURCE> -->
   <!-- See: ~/Projects/antidesign/design-md/<DESIGN_SOURCE>/ for preview HTML -->

   ```

**If `DESIGN_SOURCE` is `skeleton`**:

1. Read the skeleton template:
   ```
   Read ~/.claude/skills/proj-init/templates/design-md/standard.md
   ```

2. Replace `{{PLACEHOLDER}}` variables and write to `{{PROJECT_DIR}}/DESIGN.md`.

### 4.4 Create GCP config

Write the gcloud named config file. Check first that it doesn't exist:

```bash
# Check
ls ~/.config/gcloud/configurations/config_{{GCP_CONFIG_NAME}} 2>/dev/null
```

If it doesn't exist, write:
```
~/.config/gcloud/configurations/config_{{GCP_CONFIG_NAME}}
```

With content:
```ini
[core]
account = {{GCP_ACCOUNT_EMAIL}}
project = {{GCP_PROJECT_ID}}

[compute]
region = {{GCP_REGION}}
```

If dev/prod, also create `config_{{GCP_CONFIG_NAME_DEV}}` with the dev project ID.

### 4.5 Update root CLAUDE.md

Read `/Users/x/Projects/CLAUDE.md`. Find the last line of the GCP Project Map table (the last line starting with `|` before a blank line after line 8). Insert a new row after it:

```
| {{GCP_CONFIG_NAME}} | {{GCP_ACCOUNT_EMAIL}} | {{GCP_PROJECT_ID}} | {{GCP_REGION}} | ~/Projects/{{PROJECT_NAME}} |
```

Pad columns to match existing alignment. Use the Edit tool for this.

If dev/prod, add a second row for the dev config.

### 4.6 Run plugins

For each selected plugin, read `~/.claude/skills/proj-init/plugins/<plugin>.md` and follow its instructions to create additional files in the project directory.

### 4.7 Initialize git

```bash
cd {{PROJECT_DIR}} && git init && git add -A && git commit -m "Initial scaffold via proj-init"
```

### 4.8 Allow direnv

```bash
cd {{PROJECT_DIR}} && direnv allow
```

## Phase 5: Report

Print a completion report:

```
=== Created: ~/Projects/{{PROJECT_NAME}} ===

Files:
  .gitignore, .envrc, .env.example
  CLAUDE.md, AGENTS.md
  DESIGN.md (sourced from: <brand> | blank skeleton)
  .mcp.json, .claude/settings.local.json
  package.json, tsconfig.json, vitest.config.ts
  scripts/deploy.sh, scripts/lib/common.sh
  [+ plugin files if any]

Design:
  Source: antidesign/<brand> (or skeleton)
  Preview: ~/Projects/antidesign/design-md/<brand>/preview.html

GCP:
  Config: {{GCP_CONFIG_NAME}} -> {{GCP_PROJECT_ID}} ({{GCP_REGION}})
  Root CLAUDE.md updated with new project entry.

Next steps:
  cd ~/Projects/{{PROJECT_NAME}}
  pnpm install
  pnpm dev

  To authenticate GCP:
    gcloud config configurations activate {{GCP_CONFIG_NAME}}
    gcloud auth login

  To customize the design system further:
    /design-consultation
```

## Important Rules

- **Never overwrite existing files.** Check before every write. Skip with a warning if the file exists.
- **Always read templates from the skill directory.** Do not hardcode template content.
- **Replace ALL {{PLACEHOLDER}} variables** before writing. Verify no unreplaced placeholders remain.
- **Do NOT modify antidesign DESIGN.md content** -- copy it verbatim (with the source comment header).
- **Pad the CLAUDE.md table row** to match existing column widths.
- The `.envrc` file should NOT be committed to git (it's in .gitignore). But it IS created in the working directory.
- The `.claude/` directory should NOT be committed to git (it's in .gitignore).

## Design Recommendation Reference

Full list of available design systems in `~/Projects/antidesign/design-md/`:

### AI & Machine Learning
`claude`, `cohere`, `elevenlabs`, `minimax`, `mistral.ai`, `ollama`, `opencode.ai`, `replicate`, `runwayml`, `together.ai`, `voltagent`, `x.ai`

### Developer Tools & Platforms
`cursor`, `expo`, `linear.app`, `lovable`, `mintlify`, `posthog`, `raycast`, `resend`, `sentry`, `supabase`, `superhuman`, `vercel`, `warp`, `zapier`

### Infrastructure & Cloud
`clickhouse`, `composio`, `hashicorp`, `mongodb`, `sanity`, `stripe`

### Design & Productivity
`airtable`, `cal`, `clay`, `figma`, `framer`, `intercom`, `miro`, `notion`, `pinterest`, `webflow`

### Fintech & Crypto
`coinbase`, `kraken`, `revolut`, `wise`

### Enterprise & Consumer
`airbnb`, `apple`, `bmw`, `ibm`, `nvidia`, `spacex`, `spotify`, `uber`
