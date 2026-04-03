# Repository Guidelines

## Project Structure
{{PROJECT_STRUCTURE_BLOCK}}

## Build, Test, and Development Commands
- `pnpm install` sets up dependencies.
{{COMMANDS_BLOCK}}

## Coding Style & Naming Conventions
- TypeScript is the default language; strict mode enabled.
- 2-space indentation, double quotes.
- React components use PascalCase.
- Hooks use `useX` naming convention.
- Functions and variables use camelCase.
- File naming: kebab-case for utility files, PascalCase for React component files.

## Testing Guidelines
- Test framework: Vitest.
- Test files: `*.test.ts` or `*.test.tsx` alongside source files, or in `__tests__/` directories.
- No explicit coverage thresholds; keep tests focused on behavior changes.
- Run `pnpm test` before claiming work is done.

## Commit & Pull Request Guidelines
- Recent commits use prefixes like `feat:`, `fix:`, `add:`, `update:`, `chore:`, `docs:`, `test:`, `refactor:`; follow the same style.
- PRs should include a short summary, affected areas, linked issues, and screenshots for UI changes.
- Call out any required env vars or setup steps in the PR description.

## Configuration & Secrets
- Environment files live in `.env.local` (never committed).
- Never commit secrets; document new variables in `.env.example`.
- GCP secrets should use Secret Manager, not env files.
- direnv handles GCP config switching automatically.

## Verification Before Completion

Run this full check before claiming done:

```bash
pnpm typecheck
pnpm lint
pnpm test
pnpm build
```

If any step cannot run, explicitly report what was skipped and why.
