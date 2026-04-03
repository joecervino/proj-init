# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Tech Stack

- **Architecture**: pnpm monorepo (apps + packages)
- **Language**: TypeScript (strict mode)
- **Package Manager**: pnpm (workspaces)
- **Testing**: Vitest
- **Deployment**: GCP Cloud Run

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
pnpm dev --filter web               # Start web app only
pnpm dev --filter api-service       # Start API only
pnpm build                          # Build all packages
pnpm build --filter web             # Build web only
pnpm test                           # Run all tests
pnpm typecheck                      # TypeScript check all packages
pnpm lint                           # Lint all packages
```

## Project Structure

```
apps/
  web/              # Frontend (Next.js or Vite/React)
  api-service/      # Backend API (Fastify)
packages/
  core/             # Shared library (@{{PROJECT_NAME}}/core)
scripts/
  deploy/           # Deployment scripts
  gcp/              # GCP automation
docs/               # Project documentation
```

## Rules for Agents

1. **Verify deploy target.** Before `gcloud run deploy` or similar, confirm `$GCP_PROJECT_ID` is `{{GCP_PROJECT_ID}}`.
2. **Always pass `--project=$GCP_PROJECT_ID`** in gcloud commands.
3. **Never run `gcloud config configurations activate`.** direnv handles it.
4. **Use pnpm workspace filters** for package-specific commands: `pnpm --filter <package> <command>`.
5. **Shared code goes in `packages/core`**, not duplicated across apps.
6. **Secrets go in `.env.local`** (never committed). Document new vars in `.env.example`.
7. **Run the full check** before claiming done: `pnpm typecheck && pnpm lint && pnpm test && pnpm build`.
