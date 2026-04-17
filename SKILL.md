---
name: proj-init
description: Initialize a new project or augment an existing repo with CLAUDE.md, AGENTS.md, DESIGN.md (from antidesign), direnv GCP isolation, devcontainer-local GCP auth isolation, ruflo/claude-flow config, deploy scripts, and optimized folder structure. Use when starting a new project repo or adding standard config to an existing one.
---

# proj-init -- Project Initialization Skill

You are initializing a new project or augmenting an existing repo. Follow this workflow exactly.

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

Store whether the design repo is available. If missing, you'll fall back to the skeleton template.

## Phase 0: Detect Mode

Determine whether this is a **new project** or an **existing repo augmentation**.

Check the current working directory for existing project signals:

```bash
ls package.json .git CLAUDE.md AGENTS.md .envrc .mcp.json tsconfig.json \
  .devcontainer/devcontainer.json .devcontainer/post-create.sh \
  scripts/dev-auth-bootstrap.sh scripts/dev-auth-ensure-sa.sh scripts/dev-auth-doctor.sh scripts/dev-auth-reset.sh \
  docs/local-dev-gcp.md 2>/dev/null
```

Also check if the user explicitly named a directory:
- If the user said `/proj-init` with no arguments and we're inside a project directory (has `package.json` or `.git`), default to **augment mode**.
- If the user said `/proj-init` from `~/Projects` (the workspace root, not inside a project), default to **new project mode**.

Ask the user to confirm the mode:

**Question** (header: "Mode"):
- **New project** -- Create a fresh repo from scratch in ~/Projects/
- **Augment this repo** -- Add missing config files and improve existing ones in the current directory

Store the result as `MODE` (`new` or `augment`).

---

If `MODE` is `augment`, proceed to **Phase 0A: Audit Existing Repo**.
If `MODE` is `new`, skip to **Phase 1: Gather Project Details** (the original flow).

## Phase 0A: Audit Existing Repo

Scan the current project directory to understand what already exists. Read and catalog each file:

```bash
# What exists?
ls -la package.json CLAUDE.md AGENTS.md DESIGN.md .envrc .env.example .mcp.json .gitignore \
  tsconfig.json vitest.config.ts scripts/deploy.sh scripts/lib/common.sh \
  .devcontainer/devcontainer.json .devcontainer/post-create.sh \
  scripts/dev-auth-bootstrap.sh scripts/dev-auth-ensure-sa.sh scripts/dev-auth-doctor.sh scripts/dev-auth-reset.sh \
  docs/local-dev-gcp.md .claude/settings.local.json 2>/dev/null
```

Build an **audit table** of every managed file:

| File | Status | Notes |
|------|--------|-------|
| `.gitignore` | exists / missing | |
| `.envrc` | exists / missing | Read to extract GCP config if present |
| `.env.example` | exists / missing | |
| `CLAUDE.md` | exists / missing | Read to check if it's the generic GCP table copy or project-specific |
| `AGENTS.md` | exists / missing | |
| `DESIGN.md` | exists / missing | |
| `.mcp.json` | exists / missing | Read to check if claude-flow is already configured |
| `.claude/settings.local.json` | exists / missing | |
| `package.json` | exists / missing | Read to extract project name, scripts |
| `tsconfig.json` | exists / missing | |
| `vitest.config.ts` | exists / missing | |
| `scripts/deploy.sh` | exists / missing | |
| `scripts/lib/common.sh` | exists / missing | |
| `.devcontainer/devcontainer.json` | exists / missing | Merge if exists; ensure repo-local `CLOUDSDK_CONFIG` |
| `.devcontainer/post-create.sh` | exists / missing | Initializes repo-local auth directories |
| `scripts/dev-auth-bootstrap.sh` | exists / missing | Auth bootstrap helper (impersonation -> WIF -> key) |
| `scripts/dev-auth-ensure-sa.sh` | exists / missing | One-time IAM prep helper for local impersonation |
| `scripts/dev-auth-doctor.sh` | exists / missing | CLI + ADC diagnostics |
| `scripts/dev-auth-reset.sh` | exists / missing | Repo-local auth cleanup |
| `docs/local-dev-gcp.md` | exists / missing | Local devcontainer + auth setup doc |

**Auto-detect from existing files:**
- `PROJECT_NAME`: from `package.json` `name` field, or directory basename
- `PROJECT_DESCRIPTION`: from `package.json` `description` field, or CLAUDE.md first paragraph
- `GCP_CONFIG_NAME`, `GCP_PROJECT_ID`, `GCP_REGION`: from `.envrc` if it exists
- `GCP_ACCOUNT_EMAIL`: from gcloud config file if the config name is found in `.envrc`
- Project type: infer from directory structure (`src/app` → nextjs, `apps/` → monorepo, `functions/` → cloud-functions, `src/routes` → api-only, else minimal)

Present the audit results to the user:

```
=== Existing Repo Audit ===
  Directory:    <current dir>
  Project:      <detected name>
  Type:         <detected type>
  GCP Config:   <detected or "not configured">

  Files present:  .gitignore, package.json, tsconfig.json, ...
  Files missing:  CLAUDE.md, AGENTS.md, DESIGN.md, .mcp.json, ...
  Files to review: <files that exist but may need updates>
```

Then ask what to do:

**Question** (header: "Scope"):
- **Full augment** -- Add all missing files and review existing ones for improvements
- **Missing only** -- Only add files that don't exist, don't touch existing files
- **Pick and choose** -- Let me select which files to add/update

If "Pick and choose", show a multi-select with each missing and existing file as options.

## Phase 1: Gather Project Details

### For NEW projects (MODE=new)

Follow the original flow:

#### Round 1: Identity & GCP

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

### For AUGMENT mode (MODE=augment)

Only ask for values that couldn't be auto-detected. Pre-fill detected values as defaults.

**If GCP is not configured** (no `.envrc` with GCP vars), ask:
1. GCP account email (header: "GCP Account")
2. GCP project ID (header: "GCP Project")
3. GCP region (header: "Region")

**If GCP is already configured**, skip GCP questions entirely -- use the detected values.

**If project name/description are detected**, skip those questions.

**Always confirm the detected project type** -- show it as the default option.

### Round 2: Type & Options (both modes)

For new projects, ask all 4 questions. For augment, only ask what's unresolved:

1. **Project type** (header: "Type") -- skip if auto-detected and confirmed
   - Options: nextjs, monorepo, cloud-functions, api-only, minimal

2. **GCP region** (header: "Region") -- skip if already in .envrc
   - Default from `DEFAULT_REGION` in defaults.conf
   - Options: us-central1, us-west1, us-east1, australia-southeast1

3. **Dev/prod environment switching?** (header: "Dev/Prod") -- skip if .envrc already has conditional logic
   - Options: No (single environment), Yes (creates dev config + conditional .envrc)

4. **Extension bundles** (header: "Extensions")
   - Multi-select options: gcp, aws, terraform, jupyter, mermaid, n8n, neon, figma
   - New mode default: pre-select `gcp`
   - Augment mode default: pre-select detected bundles from existing repo signals, then allow override
   - Detection hints for augment mode:
     - `gcp`: `.envrc` has GCP vars, or existing devcontainer already has `googlecloudtools.cloudcode` / `google.geminicodeassist`
     - `aws`: existing devcontainer has AWS Toolkit / Amazon Q extensions
     - `terraform`: repo has `*.tf` or `*.tfvars` files, or existing devcontainer has `hashicorp.terraform`
     - `jupyter`: existing devcontainer has Python/Jupyter extension IDs
     - `mermaid`: existing devcontainer has `mermaidchart.vscode-mermaid-chart`
     - `n8n`: existing devcontainer has `ivov.n8n-utils` or `thorclient.n8n-atom-vscode`
     - `neon`: existing devcontainer has `databricks.neon-local-connect`
     - `figma`: existing devcontainer has `figma.figma-vscode-extension`

### Round 3: Design System Selection (both modes)

**Skip this round if DESIGN.md already exists** (in augment mode) unless the user selected it for review in "Pick and choose".

If the antidesign repo is NOT available, skip this round and use the skeleton template.

#### Question 1: Target market & industry (header: "Market")

Options:
- **Developer tools & APIs** -- SaaS for developers, CLIs, platforms, integrations
- **AI & Machine learning** -- AI products, model APIs, ML infrastructure
- **Fintech & Payments** -- Banking, crypto, payments, financial services
- **Consumer & Marketplace** -- Consumer apps, marketplaces, media, social
- **Enterprise & B2B** -- Enterprise software, infrastructure, cloud services

#### Question 2: Visual aesthetic (header: "Aesthetic")

Options:
- **Minimal & typography-first** -- Clean whitespace, tight letter-spacing, type carries the design.
- **Warm & approachable** -- Organic shapes, warm colors, generous spacing.
- **Bold & dark-native** -- Dark backgrounds, high contrast, vivid accents.
- **Clean & precise** -- Balanced layouts, neutral palette, systematic spacing.

#### Recommend & Select Design System (header: "Design")

Use the mapping table:

| Market | Minimal & typography | Warm & approachable | Bold & dark-native | Clean & precise |
|--------|---------------------|--------------------|--------------------|-----------------|
| Developer tools | vercel, linear.app, resend | notion, mintlify, intercom | cursor, supabase, warp | figma, expo, stripe |
| AI & ML | vercel, linear.app, opencode.ai | claude, cohere, ollama | mistral.ai, x.ai, elevenlabs | replicate, together.ai, runwayml |
| Fintech | stripe, wise, revolut | revolut, wise, intercom | kraken, coinbase, kraken | stripe, wise, coinbase |
| Consumer | uber, pinterest, airbnb | airbnb, spotify, pinterest | spotify, bmw, spacex | apple, pinterest, uber |
| Enterprise | hashicorp, mongodb, sanity | intercom, airtable, miro | nvidia, spacex, clickhouse | ibm, apple, hashicorp |

Show top 3 + "Blank skeleton" option. Read first ~20 lines of each brand's DESIGN.md for preview.

### Round 4: Plugins (optional, both modes)

In new project mode, auto-discover available plugins from `plugins/*.md`.

For new projects, pre-select `graphify` and `caveman` by default. Also pre-select any plugin names listed in `DEFAULT_PLUGINS` from `defaults.conf`.

Show a multi-select list of available plugins so the user can remove defaults or add others.

In augment mode, auto-detect existing plugins:
- If `.github/workflows/ci.yml` exists, pre-select ci-github-actions as "already present"
- If `cloudbuild.yaml` exists, pre-select ci-cloud-build as "already present"
- If `Dockerfile` exists, pre-select docker as "already present"
- If `.graphifyignore` exists, or `graphify-out/` exists, or `AGENTS.md` mentions `graphify`, pre-select graphify as "already present"
- If `AGENTS.md` mentions `caveman`, pre-select caveman as "already present"

Only show plugins that are NOT already present.

## Phase 2: Derive Variables

Same as before -- compute all template variables from gathered inputs.

| Variable | Value |
|----------|-------|
| `{{PROJECT_NAME}}` | The kebab-case project name |
| `{{PROJECT_DESCRIPTION}}` | The one-sentence description |
| `{{GCP_CONFIG_NAME}}` | Same as project name (unless user overrides) |
| `{{GCP_ACCOUNT_EMAIL}}` | The GCP account email |
| `{{GCP_PROJECT_ID}}` | The GCP project ID |
| `{{GCP_REGION}}` | The selected region |
| `{{PROJECT_DIR}}` | The project directory (cwd for augment, ~/Projects/name for new) |
| `{{PROJECT_NAME_UPPER}}` | Uppercase with underscores (for env var prefix in devprod) |
| `{{GCP_CONFIG_NAME_DEV}}` | `{{GCP_CONFIG_NAME}}-dev` (if devprod) |
| `{{GCP_PROJECT_ID_DEV}}` | The dev project ID (if devprod) |
| `{{DEFAULT_PNPM_VERSION}}` | From defaults.conf |
| `{{DEFAULT_NODE_VERSION}}` | From defaults.conf |
| `{{EXTENSION_BUNDLES}}` | Comma-separated selected bundle names |
| `{{DEVCONTAINER_EXTENSIONS_JSON}}` | JSON array for `.devcontainer/devcontainer.json` `extensions` |
| `DESIGN_SOURCE` | Brand name from antidesign (e.g., `vercel`) or `skeleton` |
| `MODE` | `new` or `augment` |

### Extension Bundle Resolution

Use this as the single source of truth for devcontainer extension selection.

Baseline extensions (always include):

- `aaron-bond.better-comments`
- `anthropic.claude-code`
- `bengreenier.vscode-node-readme`
- `christian-kohler.path-intellisense`
- `dbaeumer.vscode-eslint`
- `eamodio.gitlens`
- `emmanuelbeziat.vscode-great-icons`
- `esbenp.prettier-vscode`
- `formulahendry.auto-rename-tag`
- `github.copilot-chat`
- `mattpocock.ts-error-translator`
- `mgmcdermott.vscode-language-babel`
- `openai.chatgpt`
- `redhat.vscode-yaml`
- `sdras.night-owl`
- `wix.vscode-import-cost`
- `xabikos.reactsnippets`

Permanently remove/exclude:

- `streetsidesoftware.code-spell-checker`
- `anseki.vscode-color`
- `naumovs.color-highlight`
- `xabikos.javascriptsnippets`
- `wallabyjs.quokka-vscode`
- `sketchbuch.vsc-quokka-statusbar`
- `mrmlnc.vscode-scss`
- `bradlc.vscode-tailwindcss`

Managed bundles:

- `aws`: `amazonwebservices.amazon-q-vscode`, `amazonwebservices.aws-toolkit-vscode`
- `gcp`: `googlecloudtools.cloudcode`, `google.geminicodeassist`
- `terraform`: `hashicorp.terraform`
- `jupyter`: `ms-python.debugpy`, `ms-python.python`, `ms-python.vscode-pylance`, `ms-python.vscode-python-envs`, `ms-toolsai.jupyter`, `ms-toolsai.jupyter-keymap`, `ms-toolsai.jupyter-renderers`, `ms-toolsai.vscode-jupyter-cell-tags`, `ms-toolsai.vscode-jupyter-slideshow`
- `mermaid`: `mermaidchart.vscode-mermaid-chart`
- `n8n`: `ivov.n8n-utils`, `thorclient.n8n-atom-vscode`
- `neon`: `databricks.neon-local-connect`
- `figma`: `figma.figma-vscode-extension`

Compute `{{DEVCONTAINER_EXTENSIONS_JSON}}` as:

1. Start from the baseline list.
2. Add extension IDs from selected bundles.
3. Remove any permanently excluded IDs.
4. De-duplicate while preserving first occurrence order.

## Phase 3: Show Summary & Confirm

**For new projects**, show the full summary as before.

**For augment mode**, show what will change:

```
=== Augment Plan for <project-dir> ===

  CREATE (missing files):
    CLAUDE.md, AGENTS.md, DESIGN.md, .mcp.json, ...

  MERGE (improve existing files):
    .gitignore -- add 8 missing entries (direnv, claude, gstack sections)
    package.json -- add 3 missing scripts (typecheck, ci, test:coverage)
    .mcp.json -- add claude-flow server (preserving existing servers)
    .devcontainer/devcontainer.json -- ensure repo-local CLOUDSDK_CONFIG + post-create
    .env.example -- ensure non-secret local auth placeholders

  SKIP (already good):
    tsconfig.json, vitest.config.ts, ...

  GCP:
    Config: <status>
    Root CLAUDE.md: <will update / already listed>
  Extensions:
    Bundles: <selected bundles>
```

Ask user to confirm.

## Phase 4: Create / Augment Project

### For NEW projects (MODE=new)

Follow the original flow exactly -- create directory structure, write all files, create GCP config, update root CLAUDE.md, run plugins, git init, direnv allow.

### For AUGMENT mode (MODE=augment)

Use **smart merge strategies** per file type. The goal is to produce the best possible final version by combining existing content with template improvements.

#### 4.1 Create missing directories only

Read the scaffold file. Only `mkdir -p` directories that don't already exist. Never delete or reorganize existing directories.

#### 4.2 Handle each file with the appropriate strategy

**Strategy: CREATE** (file does not exist) -- write from template with placeholders replaced. Same as new mode.

**Strategy: MERGE** (file exists and can be improved) -- read both the existing file and the template, then produce a merged result. Specifics per file:

##### `.gitignore` -- APPEND missing entries
1. Read existing `.gitignore`
2. Read template `.gitignore`
3. For each line in the template, check if the existing file already contains it (or an equivalent pattern)
4. Append any missing entries, grouped under a `# Added by proj-init` comment
5. Never remove existing entries

##### `.devcontainer/devcontainer.json` -- CREATE if missing, MERGE if exists
- If missing: create from `templates/devcontainer/devcontainer.json`.
- If missing, replace the string token `"{{DEVCONTAINER_EXTENSIONS_JSON}}"` with the computed JSON array literal.
- If exists: preserve existing image/features/customizations and merge in:
  - `remoteEnv.CLOUDSDK_CONFIG=${containerWorkspaceFolder}/.devcontainer/.state/gcloud`
  - `postCreateCommand=bash .devcontainer/post-create.sh` (append to existing command if needed)
- Required skills/plugins mounts (always-on, read-only):
  - `source=${localWorkspaceFolderBasename}-node_modules,target=${containerWorkspaceFolder}/node_modules,type=volume`
  - `source=${localWorkspaceFolderBasename}-pnpm-store,target=/home/node/.pnpm-store,type=volume`
  - `source=${localEnv:HOME}/.claude/skills,target=/home/node/.claude/skills,type=bind,readonly`
  - `source=${localEnv:HOME}/.claude/plugins,target=/home/node/.claude/plugins,type=bind,readonly`
  - `source=${localEnv:HOME}/.codex/skills,target=/home/node/.codex/skills,type=bind,readonly`
  - `source=${localEnv:HOME}/.codex/plugins,target=/home/node/.codex/plugins,type=bind,readonly`
  - `source=${localEnv:HOME}/.agents/skills,target=/home/node/.agents/skills,type=bind,readonly`
  - `source=${localEnv:HOME}/Projects/.agents/skills,target=/home/node/Projects/.agents/skills,type=bind,readonly`
- For `customizations.vscode.extensions` merge behavior:
  - Preserve unknown/non-managed extension IDs already in the repo.
  - Remove all permanently excluded extension IDs.
  - Add extension IDs for selected managed bundles.
  - Remove extension IDs for unselected managed bundles.
  - De-duplicate while preserving stable order.
- For `mounts` merge behavior:
  - If `mounts` is missing, create it with the required mounts.
  - If `mounts` exists, append any missing required mounts.
  - Never remove unrelated existing mounts.
- Never remove existing repo-specific devcontainer behavior.

##### `.devcontainer/post-create.sh` -- CREATE if missing, PRESERVE if exists
- If missing: create from `templates/devcontainer/post-create.sh`.
- If exists: preserve existing logic, and ensure it also:
  - initializes repo-local auth directories under `.devcontainer/.state`, `.devcontainer/.auth`, `.devcontainer/.secrets`
  - detects pnpm repos (`package.json` + `pnpm-lock.yaml`)
  - verifies `node_modules` is writable and repairs ownership when needed
  - uses `/home/node/.pnpm-store` as primary store
  - repairs unwritable primary store with `sudo chown -R "$(id -u):$(id -g)" /home/node/.pnpm-store` when possible
  - falls back to `.devcontainer/.state/pnpm-store` when primary store remains unwritable
  - retries `pnpm install` once with reduced concurrency when install is killed (exit 137)
  - runs `pnpm install --no-frozen-lockfile` in-container using the selected writable store
  - fails fast with explicit remediation guidance if `node_modules` remains unwritable
  - emits clear logs for dependency bootstrap and selected store path

##### `.envrc` -- CREATE if missing, SKIP if exists
- If missing: create from template
- If exists: read it, verify GCP vars are set. If GCP vars are missing, offer to add them. Never overwrite existing .envrc logic.

##### `.env.example` -- APPEND local auth placeholders
- Ensure these non-secret keys exist (append if missing):
  - `GCP_DEV_ME_USER_EMAIL=`
  - `GCP_DEV_SA_ID=local-dev-codex`
  - `GCP_DEV_IMPERSONATE_SERVICE_ACCOUNT=`
  - `GCP_DEV_WIF_CREDENTIAL_FILE=`
  - `GCP_DEV_CREDENTIAL_FILE=`
- Never add secret values.

##### `CLAUDE.md` -- SMART MERGE
1. Read the existing CLAUDE.md
2. **If it's the generic GCP table copy** (matches the root ~/Projects/CLAUDE.md content): Replace entirely with a project-specific version from the template. This is the known anti-pattern -- every project currently has the same generic file.
3. **If it's already project-specific** (has custom content beyond the GCP table): Preserve it. Read the template and check for missing sections (Commands, Project Structure, Rules for Agents). Offer to append any missing sections at the end.

##### `AGENTS.md` -- CREATE if missing, PRESERVE if exists
- Existing AGENTS.md files are project-specific (like Bidit's). Never overwrite.
- If missing: create from template.

##### `DESIGN.md` -- CREATE if missing, ASK if exists
- If missing: go through the antidesign selection flow (Round 3).
- If exists: ask the user whether to keep, replace, or merge.

##### `.mcp.json` -- DEEP MERGE
1. Read existing `.mcp.json` and parse as JSON
2. Read template `.mcp.json`
3. If `claude-flow` server is already present in `mcpServers`: skip
4. If `claude-flow` is missing: add it to `mcpServers` while preserving ALL existing servers
5. Write the merged JSON back

##### `.claude/settings.local.json` -- DEEP MERGE
1. Read existing file (if any) and parse
2. Read template
3. Merge `permissions.allow` arrays -- add missing entries from template, keep existing ones
4. Preserve any other settings the user has added

##### `package.json` -- MERGE SCRIPTS ONLY
1. Read existing `package.json`
2. Read template `package.json`
3. **Only merge the `scripts` field**: for each script in the template, if the key doesn't exist in the existing package.json, add it. Never overwrite existing scripts.
4. Do NOT touch `dependencies`, `devDependencies`, `name`, `version`, or any other fields.
5. Write the merged result.

##### `tsconfig.json` -- CREATE if missing, SKIP if exists
- Existing tsconfig is authoritative. Never overwrite.

##### `vitest.config.ts` -- CREATE if missing, SKIP if exists

##### `scripts/deploy.sh` -- CREATE if missing, CHECK if exists
- If missing: create from template with project guard.
- If exists: read it and verify it has a project guard (`EXPECTED_PROJECT=`). If not, warn the user that the deploy script lacks a project guard but do NOT modify it.

##### `scripts/lib/common.sh` -- CREATE if missing, SKIP if exists

##### `scripts/dev-auth-bootstrap.sh` -- CREATE if missing, CHECK if exists
- If missing: create from `templates/scripts/dev-auth-bootstrap.sh`.
- If exists: preserve repo-specific custom logic, but ensure it supports:
  - default impersonation mode
  - wif fallback mode
  - key fallback mode
  - fail-fast validation for impersonation service account format (`*.iam.gserviceaccount.com`)
  - actionable hints for impersonation misconfiguration (project mismatch / Gaia id not found)
  - repo-local `CLOUDSDK_CONFIG` under `.devcontainer/.state/gcloud`

##### `scripts/dev-auth-ensure-sa.sh` -- CREATE if missing, CHECK if exists
- If missing: create from `templates/scripts/dev-auth-ensure-sa.sh`.
- If exists: preserve repo-specific custom logic, but ensure it supports:
  - `--project`, `--me`, `--sa-id`, `--region`, repeatable `--sa-role`, `--dry-run`
  - clearing stale impersonation config before IAM operations
  - idempotent SA creation
  - TokenCreator grant for `user:<me>` on the target service account
  - optional project role grants to `serviceAccount:<sa>`
  - admin handoff command block on IAM permission failures
  - printing an exact follow-up `dev-auth-bootstrap.sh impersonation ...` command

##### `scripts/dev-auth-doctor.sh` -- CREATE if missing, CHECK if exists
- If missing: create from `templates/scripts/dev-auth-doctor.sh`.
- If exists: ensure it validates both CLI auth and ADC auth independently.

##### `scripts/dev-auth-reset.sh` -- CREATE if missing, CHECK if exists
- If missing: create from `templates/scripts/dev-auth-reset.sh`.
- If exists: ensure it only clears repo-local auth state.

##### `docs/local-dev-gcp.md` -- CREATE if missing, REFRESH hints if exists
- If missing: create from `templates/docs/local-dev-gcp.md`.
- If exists: preserve project-specific detail, but ensure it documents:
  - dependency-isolated Node setup (`node_modules` and pnpm store volumes)
  - why mount options do not reliably set uid/gid for these named volumes in this setup
  - self-healing behavior for both `node_modules` and pnpm store (ownership repair + fallback store)
  - retry behavior and manual command when install is killed by memory pressure (exit 137)
  - one-time cleanup commands for stale host `node_modules` when migrating existing repos
  - quick verification commands for writable `node_modules`, writable pnpm store, and Linux-native modules (esbuild check)
  - note that `Command "tsx" not found` usually means install/linking was interrupted
  - one-time IAM setup with `dev-auth-ensure-sa.sh`
  - how to reopen in devcontainer
  - first-time auth bootstrap
  - doctor checks for CLI + ADC
  - reset behavior and manual IAM prerequisites

#### 4.3 Write DESIGN.md (same logic as new mode, but respects existing)

If DESIGN.md exists and user chose to keep it, skip.
Otherwise follow the antidesign/skeleton flow.

#### 4.4 Create GCP config (same as new mode)

Check if config exists first. If it does, skip.

#### 4.5 Update root CLAUDE.md

Check if the project is already in the GCP Project Map table. If so, skip. If not, add a new row.

#### 4.6 Run plugins (same as new mode, skip already-present plugins)

#### 4.7 Git commit (augment mode)

Do NOT run `git init` (repo already exists). Instead, if there's a git repo:

```bash
git add -A && git status
```

Show the user what changed and let them decide whether to commit. Suggest a commit message:

```
proj-init: add missing config files

Added: <list of new files>
Updated: <list of merged files>
```

Do NOT auto-commit. Ask the user first.

#### 4.8 Allow direnv

If `.envrc` was created or modified:
```bash
direnv allow
```

## Phase 5: Report

**For new projects**, show the original completion report.

**For augment mode**, show a detailed changelog:

```
=== Augmented: <project-dir> ===

Created:
  + CLAUDE.md (project-specific, replaces generic GCP table)
  + AGENTS.md
  + DESIGN.md (sourced from: <brand>)
  + .mcp.json (claude-flow v3)

Merged:
  ~ .gitignore (added 8 entries: direnv, claude, gstack sections)
  ~ package.json (added scripts: typecheck, ci, test:coverage)

Unchanged:
  = tsconfig.json (already exists)
  = vitest.config.ts (already exists)

GCP:
  Config: <status>
  Root CLAUDE.md: <updated / already present>

Next steps:
  Review the changes with: git diff
  Commit when ready: git add -A && git commit -m "proj-init: add config files"
```

## Important Rules

- **In augment mode, NEVER delete or overwrite existing content** unless the user explicitly approved it (e.g., replacing the generic CLAUDE.md, or replacing DESIGN.md).
- **Always read existing files before deciding the merge strategy.** Don't assume a file needs updating without reading it.
- **Merge results should be the BEST of both** -- keep existing customizations, add missing standard pieces.
- **Show the user what will change** before making changes in augment mode.
- **Always read templates from the skill directory.** Do not hardcode template content.
- **Replace ALL {{PLACEHOLDER}} variables** before writing. Verify no unreplaced placeholders remain.
- **Do NOT modify antidesign DESIGN.md content** -- copy it verbatim (with the source comment header).
- **Pad the CLAUDE.md table row** to match existing column widths.
- The `.envrc` file should NOT be committed to git (it's in .gitignore). But it IS created in the working directory.
- The `.claude/` directory should NOT be committed to git (it's in .gitignore).
- Ensure `.gitignore` includes repo-local dev auth paths:
  - `.devcontainer/.state/`
  - `.devcontainer/.auth/`
  - `.devcontainer/.secrets/`

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
