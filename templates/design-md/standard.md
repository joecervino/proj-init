# Design System -- {{PROJECT_NAME}}

> Run `/design-consultation` to generate a full design system with typography,
> color palette, spacing, and motion specs.

## Brand

- **Name**: {{PROJECT_NAME}}
- **Description**: {{PROJECT_DESCRIPTION}}
- **Personality**: [TBD]

## Color Palette

| Token          | Value   | Usage                  |
|----------------|---------|------------------------|
| `--primary`    |         | Primary actions, links |
| `--secondary`  |         | Secondary elements     |
| `--accent`     |         | Highlights, badges     |
| `--background` |         | Page background        |
| `--surface`    |         | Card/panel background  |
| `--text`       |         | Primary text           |
| `--muted`      |         | Secondary text         |
| `--border`     |         | Borders, dividers      |
| `--error`      |         | Error states           |
| `--success`    |         | Success states         |

## Typography

| Token    | Font | Size | Weight | Usage          |
|----------|------|------|--------|----------------|
| `--h1`   |      |      |        | Page titles    |
| `--h2`   |      |      |        | Section heads  |
| `--body` |      |      |        | Body text      |
| `--small`|      |      |        | Captions       |

## Spacing Scale

Base unit: 4px. Tokens: `--space-1` (4px) through `--space-12` (48px).

## Component Library

- UI framework: [Radix UI / shadcn/ui]
- Icons: [Lucide]
- Tailwind CSS for utility styling

## Motion

- Transitions: 150ms ease for micro-interactions, 300ms ease-out for layout shifts.
- No motion for users with `prefers-reduced-motion`.
