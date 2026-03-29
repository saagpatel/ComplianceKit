# ComplianceKit

[![PLpgSQL](https://img.shields.io/badge/postgresql-%23336791?style=flat-square&logo=postgresql)](#) [![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](#)

> SOC 2 readiness without the $50k consulting bill — track controls, collect evidence, and ship your audit.

ComplianceKit is a SOC 2 audit readiness workflow application built on Next.js 14 and Supabase. The current scaffold covers auth, org setup, controls seeding, and first integration flows — designed to be deployed on Vercel with Supabase handling auth and Postgres.

## Features

- **Controls library** — seed and track SOC 2 controls across Trust Service Criteria
- **Evidence collection** — attach evidence artifacts to control requirements
- **Organization setup** — multi-tenant org management with role-based access
- **Auth** — Supabase Auth with SSR-safe session handling via @supabase/ssr
- **Integration hooks** — extensible integration flow architecture for connecting data sources

## Quick Start

### Prerequisites
- Node.js 18+ and pnpm
- Supabase project (cloud or local with `supabase start`)

### Installation
```bash
git clone https://github.com/saagpatel/ComplianceKit
cd ComplianceKit
pnpm install
cp .env.example .env.local
# Add your Supabase URL and anon key to .env.local
```

### Usage
```bash
# Development
pnpm dev

# Type check
pnpm typecheck

# Build
pnpm build
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Next.js 14 (App Router) |
| Database | Supabase (PostgreSQL) |
| Auth | Supabase Auth + @supabase/ssr |
| Frontend | React 18 + TypeScript + Tailwind CSS + Radix UI |
| Deployment | Vercel |

## License

MIT
