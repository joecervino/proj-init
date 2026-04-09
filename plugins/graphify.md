---
name: graphify
description: Adds graphify defaults for knowledge-graph workflows
---

# Graphify Plugin

Add graphify defaults that work well with OpenCode projects.

## .graphifyignore

Write `{{PROJECT_DIR}}/.graphifyignore`:

```gitignore
# Build and package output
node_modules/
dist/
build/
coverage/
.next/

# Generated and local tooling output
.git/
.claude/
.claude-flow/
.gstack/
graphify-out/

# Logs and lock files
*.log
pnpm-lock.yaml
package-lock.json
yarn.lock
```

## AGENTS.md additions

Read `{{PROJECT_DIR}}/AGENTS.md` and append this section if it does not already exist:

```markdown
## Knowledge Graph Workflow (graphify)

- One-time machine setup for OpenCode:
  - `pip install graphifyy`
  - `graphify install --platform opencode`
- One-time project setup:
  - `graphify opencode install`
- Build graph for the current repo:
  - `/graphify .`
- Rebuild only changed files:
  - `/graphify . --update`
- Ask graph-driven questions:
  - `/graphify query "show auth flow"`
  - `/graphify path "NodeA" "NodeB"`

When `graphify-out/GRAPH_REPORT.md` exists, read it before broad codebase searches.
```
