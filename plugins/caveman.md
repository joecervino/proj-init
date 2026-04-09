---
name: caveman
description: Adds caveman token-efficient communication workflow guidance
---

# Caveman Plugin

Add token-efficient communication guidance for agent sessions.

## AGENTS.md additions

Read `{{PROJECT_DIR}}/AGENTS.md` and append this section if it does not already exist:

```markdown
## Token-Efficient Mode (caveman)

- One-time machine setup:
  - `npx skills add JuliusBrussee/caveman`
- Enable in a session:
  - `/caveman`
  - `/caveman lite`
  - `/caveman ultra`
- Related helpers:
  - `/caveman-commit` for concise commit messages
  - `/caveman-review` for one-line review comments
- Disable:
  - `stop caveman` or `normal mode`

Use caveman mode when you want concise responses and lower token usage.
```
