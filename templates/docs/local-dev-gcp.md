# Local Dev GCP Setup ({{PROJECT_NAME}})

This repo uses a repo-local devcontainer auth pattern to avoid cross-project credential collisions.

## 1. Open In Dev Container

1. Open the repo in VS Code.
2. Run **Dev Containers: Reopen in Container**.
3. The container runs `.devcontainer/post-create.sh`, which initializes:

- repo-local `CLOUDSDK_CONFIG` under `.devcontainer/.state/gcloud`
- helper metadata under `.devcontainer/.auth`
- optional local credential scratch space under `.devcontainer/.secrets`

## Dependency Isolation For Node Modules

This devcontainer isolates Node dependencies to avoid macOS-vs-Linux native binary mismatches (for example `@esbuild/darwin-arm64` on host vs `@esbuild/linux-arm64` in container).

- `node_modules` is mounted as a container volume at `${containerWorkspaceFolder}/node_modules`.
- Primary pnpm store is a container volume at `/home/node/.pnpm-store`.
- Docker mount options do not reliably set uid/gid ownership for these named volumes in this setup, so post-create performs ownership self-healing.
- During `.devcontainer/post-create.sh`, the container now:
  - checks writability of both `node_modules` and `/home/node/.pnpm-store`
  - attempts `sudo chown -R "$(id -u):$(id -g)"` repair when needed
  - falls back to `${containerWorkspaceFolder}/.devcontainer/.state/pnpm-store` if the primary store is still not writable
  - retries `pnpm install` once with reduced concurrency if the process is killed (exit 137)
- If `node_modules` is still not writable after repair, bootstrap fails fast with remediation guidance.

One-time migration for already-cloned repos (still recommended):

```bash
# Run on host (outside container) from repo root
rm -rf node_modules
rm -rf .pnpm-store  # optional if present in repo root
```

Then run **Dev Containers: Rebuild Container**.

Quick verification inside container:

```bash
test -w node_modules && echo "node_modules is writable"
pnpm store path
test -w "$(pnpm store path)" && echo "pnpm store is writable"
node -p "process.platform + '-' + process.arch"
ls node_modules/.pnpm | grep -E '@esbuild\\+linux-arm64|@esbuild\\+darwin-arm64'
```

Expected: writable `node_modules`, writable store path, `linux-arm64` platform, and `@esbuild+linux-arm64` present.

If install is interrupted and you see `Command "tsx" not found`, rerun install to complete linking:

```bash
pnpm install --no-frozen-lockfile --prefer-offline --child-concurrency=1 --workspace-concurrency=1 --network-concurrency=8
```

## 2. One-Time IAM Setup (Impersonation Path)

Before first bootstrap, ensure the local-dev service account exists and your user can impersonate it:

```bash
./scripts/dev-auth-ensure-sa.sh \
  --project {{GCP_PROJECT_ID}} \
  --region {{GCP_REGION}} \
  --me <you@example.com> \
  --sa-id local-dev-codex
```

Optional least-privilege starter role grants to the service account:

```bash
./scripts/dev-auth-ensure-sa.sh \
  --project {{GCP_PROJECT_ID}} \
  --region {{GCP_REGION}} \
  --me <you@example.com> \
  --sa-id local-dev-codex \
  --sa-role roles/viewer
```

If you do not have IAM permissions, use this admin handoff template:

```bash
gcloud iam service-accounts create local-dev-codex \
  --project {{GCP_PROJECT_ID}} \
  --display-name "Local Dev (Codex/Claude)"

gcloud iam service-accounts add-iam-policy-binding \
  local-dev-codex@{{GCP_PROJECT_ID}}.iam.gserviceaccount.com \
  --project {{GCP_PROJECT_ID}} \
  --member user:<you@example.com> \
  --role roles/iam.serviceAccountTokenCreator
```

## 3. First-Time Auth Bootstrap

Auth priority:

1. **Impersonation (default)**
2. **WIF fallback**
3. **Raw key fallback (last resort)**

Run one of:

```bash
./scripts/dev-auth-bootstrap.sh impersonation
./scripts/dev-auth-bootstrap.sh wif --cred-file /absolute/path/to/wif-cred-config.json
./scripts/dev-auth-bootstrap.sh key --cred-file /absolute/path/to/service-account-key.json
```

If project auto-detection is not correct, pass explicit values:

```bash
./scripts/dev-auth-bootstrap.sh impersonation --project <project-id> --region <region>
```

Project hint: `{{GCP_PROJECT_ID}}`  
Region hint: `{{GCP_REGION}}`

## 4. Validate CLI And ADC

Run:

```bash
./scripts/dev-auth-doctor.sh
```

The doctor checks both flows independently:

- CLI auth: `gcloud auth print-access-token`
- ADC auth: `gcloud auth application-default print-access-token`

## 5. Reset Repo-Local Auth State

```bash
./scripts/dev-auth-reset.sh
```

This only removes repo-local auth state under `.devcontainer/.state` and `.devcontainer/.auth`.

## 6. Manual IAM Requirements

Impersonation requires at minimum:

- a target local-dev service account
- `roles/iam.serviceAccountTokenCreator` on that service account for your human principal
- least-privilege project roles granted to the target service account

WIF fallback requires:

- a configured workload identity pool/provider and generated credential config JSON

Key fallback requires:

- a service account key file stored out-of-repo and never committed

## 7. Conditional Extension Bundles

To reduce remote extension host instability, this setup uses a lean baseline extension set plus optional bundles.

- Baseline extensions are always auto-installed.
- Optional bundles are enabled via the `proj-init` questionnaire, or by editing `.devcontainer/devcontainer.json` directly.
- After changing bundle selections, rebuild the container so VS Code applies the updated extension set.

Bundle catalog:

- `gcp`: `googlecloudtools.cloudcode`, `google.geminicodeassist`
- `aws`: `amazonwebservices.amazon-q-vscode`, `amazonwebservices.aws-toolkit-vscode`
- `terraform`: `hashicorp.terraform`
- `jupyter`: `ms-python.debugpy`, `ms-python.python`, `ms-python.vscode-pylance`, `ms-python.vscode-python-envs`, `ms-toolsai.jupyter`, `ms-toolsai.jupyter-keymap`, `ms-toolsai.jupyter-renderers`, `ms-toolsai.vscode-jupyter-cell-tags`, `ms-toolsai.vscode-jupyter-slideshow`
- `mermaid`: `mermaidchart.vscode-mermaid-chart`
- `n8n`: `ivov.n8n-utils`, `thorclient.n8n-atom-vscode`
- `neon`: `databricks.neon-local-connect`
- `figma`: `figma.figma-vscode-extension`

Permanently excluded from auto-install:

- `streetsidesoftware.code-spell-checker`
- `anseki.vscode-color`
- `naumovs.color-highlight`
- `xabikos.javascriptsnippets`
- `wallabyjs.quokka-vscode`
- `sketchbuch.vsc-quokka-statusbar`
- `mrmlnc.vscode-scss`
- `bradlc.vscode-tailwindcss`

## 8. Claude/Codex Skills & Plugins Mounts

This devcontainer mounts Claude/Codex skill and plugin directories from the host as read-only.

Mounted sources:

- `${localEnv:HOME}/.claude/skills` -> `/home/node/.claude/skills`
- `${localEnv:HOME}/.claude/plugins` -> `/home/node/.claude/plugins`
- `${localEnv:HOME}/.codex/skills` -> `/home/node/.codex/skills`
- `${localEnv:HOME}/.codex/plugins` -> `/home/node/.codex/plugins`
- `${localEnv:HOME}/.agents/skills` -> `/home/node/.agents/skills`
- `${localEnv:HOME}/Projects/.agents/skills` -> `/home/node/Projects/.agents/skills`

Notes:

- Mounts are read-only from inside the container.
- Update skills/plugins on the host; containers see changes through the bind mounts.
- Rebuild/reopen the container after changing mount configuration in `devcontainer.json`.
