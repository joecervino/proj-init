# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Tech Stack

- **Framework**: Fastify
- **Language**: TypeScript (strict mode)
- **Package Manager**: pnpm
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
pnpm dev          # Start dev server with watch
pnpm build        # Compile TypeScript
pnpm start        # Run compiled output
pnpm test         # Run tests
pnpm typecheck    # TypeScript check
pnpm lint         # Lint
pnpm ci           # Full CI check
```

## Project Structure

```
src/
  index.ts          # Entry point (Fastify server)
  routes/           # Route handlers
  lib/              # Shared utilities
  types/            # TypeScript type definitions
  test/             # Test setup and utilities
scripts/
  deploy.sh         # Cloud Run deployment (with project guard)
  lib/common.sh     # Shared script utilities
docs/               # Project documentation
```

## Rules for Agents

1. **Verify deploy target.** Confirm `$GCP_PROJECT_ID` is `{{GCP_PROJECT_ID}}` before deploying.
2. **Always pass `--project=$GCP_PROJECT_ID`** in gcloud commands.
3. **Never run `gcloud config configurations activate`.** direnv handles it.
4. **Do not bypass the project guard** in `scripts/deploy.sh`.
5. **Secrets go in `.env.local`** (never committed). Document new vars in `.env.example`.
6. **Run the full check** before claiming done: `pnpm typecheck && pnpm lint && pnpm test && pnpm build`.
