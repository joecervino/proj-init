# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Tech Stack

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
pnpm dev          # Start with watch mode
pnpm build        # Compile TypeScript
pnpm start        # Run compiled output
pnpm test         # Run tests
pnpm typecheck    # TypeScript check
```

## Project Structure

```
src/
  index.ts          # Entry point
  test/             # Test setup
scripts/            # Automation scripts
docs/               # Documentation
```

## Rules for Agents

1. **Verify deploy target.** Confirm `$GCP_PROJECT_ID` is `{{GCP_PROJECT_ID}}` before deploying.
2. **Always pass `--project=$GCP_PROJECT_ID`** in gcloud commands.
3. **Never run `gcloud config configurations activate`.** direnv handles it.
4. **Secrets go in `.env.local`** (never committed). Document new vars in `.env.example`.
