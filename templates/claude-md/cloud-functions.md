# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Tech Stack

- **Backend**: GCP Cloud Functions (TypeScript)
- **Frontend**: Next.js (App Router)
- **Language**: TypeScript (strict mode)
- **Package Manager**: pnpm (workspaces)
- **Testing**: Vitest
- **Deployment**: GCP Cloud Functions + Vercel/Cloud Run

## GCP Environment

| Variable | Value |
|----------|-------|
| Config   | `{{GCP_CONFIG_NAME}}` |
| Project  | `{{GCP_PROJECT_ID}}` |
| Region   | `{{GCP_REGION}}` |

direnv sets these automatically when you `cd` into this directory.

## Commands

```bash
pnpm install                        # Install all workspace dependencies
pnpm dev                            # Start all services
pnpm dev --filter functions         # Start functions emulator
pnpm dev --filter web               # Start web dev server
pnpm build                          # Build all
pnpm build --filter functions       # Build functions only
pnpm test                           # Run all tests
pnpm typecheck                      # TypeScript check all packages
```

## Project Structure

```
functions/
  src/              # Cloud Functions source
  package.json      # Functions dependencies
  tsconfig.json     # Functions TypeScript config
web/
  src/
    app/            # Next.js App Router
    components/     # React components
    lib/            # Shared utilities
  package.json
  tsconfig.json
scripts/
  setup/            # Infrastructure setup
  deploy/           # Deployment scripts
  smoke/            # Smoke tests
  db/               # Database scripts
  lib/common.sh     # Shared utilities
docs/               # Project documentation
```

## Rules for Agents

1. **Verify deploy target.** Confirm `$GCP_PROJECT_ID` is `{{GCP_PROJECT_ID}}` before deploying.
2. **Always pass `--project=$GCP_PROJECT_ID`** in gcloud commands.
3. **Never run `gcloud config configurations activate`.** direnv handles it.
4. **Deploy functions and web separately.** They have independent build and deploy pipelines.
5. **Secrets go in `.env.local`** (never committed). Document new vars in `.env.example`.
6. **Run smoke tests** after deployment: `scripts/smoke/`.
