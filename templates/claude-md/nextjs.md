# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Tech Stack

- **Framework**: Next.js (App Router)
- **Language**: TypeScript (strict mode)
- **Package Manager**: pnpm
- **Styling**: Tailwind CSS
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
pnpm dev          # Start dev server (Turbopack)
pnpm build        # Production build
pnpm start        # Start production server
pnpm test         # Run tests
pnpm typecheck    # TypeScript check
pnpm lint         # Lint
pnpm ci           # Full CI check (typecheck + lint + test + build)
```

## Project Structure

```
src/
  app/            # Next.js App Router pages and layouts
  components/     # React components
  lib/            # Shared utilities and helpers
  hooks/          # React hooks
  types/          # TypeScript type definitions
  schemas/        # Zod validation schemas
  server/         # Server-side code (actions, API helpers)
  styles/         # CSS / Tailwind config
  test/           # Test setup and utilities
scripts/
  deploy.sh       # Cloud Run deployment (with project guard)
  lib/common.sh   # Shared script utilities
docs/             # Project documentation
public/           # Static assets
```

## Rules for Agents

1. **Verify deploy target.** Before `gcloud run deploy` or similar, confirm `$GCP_PROJECT_ID` is `{{GCP_PROJECT_ID}}`.
2. **Always pass `--project=$GCP_PROJECT_ID`** in gcloud commands.
3. **Never run `gcloud config configurations activate`.** direnv handles it.
4. **Do not bypass the project guard** in `scripts/deploy.sh`.
5. **Secrets go in `.env.local`** (never committed). Document new vars in `.env.example`.
6. **Run the full check** before claiming done: `pnpm typecheck && pnpm lint && pnpm test && pnpm build`.
