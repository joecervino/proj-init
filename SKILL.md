---
name: proj-init
description: Initialize a new project or augment an existing repo with CLAUDE.md, AGENTS.md, DESIGN.md (from antidesign), direnv GCP isolation, ruflo/claude-flow config, deploy scripts, and optimized folder structure. Use when starting a new project repo or adding standard config to an existing one.
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
ls package.json .git CLAUDE.md AGENTS.md .envrc .mcp.json tsconfig.json 2>/dev/null
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
ls -la package.json CLAUDE.md AGENTS.md DESIGN.md .envrc .env.example .mcp.json .gitignore tsconfig.json vitest.config.ts scripts/deploy.sh scripts/lib/common.sh .claude/settings.local.json 2>/dev/null
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

For new projects, ask all 3 questions. For augment, only ask what's unresolved:

1. **Project type** (header: "Type") -- skip if auto-detected and confirmed
   - Options: nextjs, monorepo, cloud-functions, api-only, minimal

2. **GCP region** (header: "Region") -- skip if already in .envrc
   - Default from `DEFAULT_REGION` in defaults.conf
   - Options: us-central1, us-west1, us-east1, australia-southeast1

3. **Dev/prod environment switching?** (header: "Dev/Prod") -- skip if .envrc already has conditional logic
   - Options: No (single environment), Yes (creates dev config + conditional .envrc)

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

In augment mode, auto-detect existing plugins:
- If `.github/workflows/ci.yml` exists, pre-select ci-github-actions as "already present"
- If `cloudbuild.yaml` exists, pre-select ci-cloud-build as "already present"
- If `Dockerfile` exists, pre-select docker as "already present"

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
| `DESIGN_SOURCE` | Brand name from antidesign (e.g., `vercel`) or `skeleton` |
| `MODE` | `new` or `augment` |

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

  SKIP (already good):
    tsconfig.json, vitest.config.ts, ...

  GCP:
    Config: <status>
    Root CLAUDE.md: <will update / already listed>
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

##### `.envrc` -- CREATE if missing, SKIP if exists
- If missing: create from template
- If exists: read it, verify GCP vars are set. If GCP vars are missing, offer to add them. Never overwrite existing .envrc logic.

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
