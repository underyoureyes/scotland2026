# 🗺️ Trip Planner App — PoC

A private, invite-only iPhone PWA for planning road trips with Claude AI.

## Quick start

### 1. Prerequisites

- Node.js 18+
- [Supabase](https://supabase.com) project (free tier)
- [Vercel](https://vercel.com) account (free tier)
- [Anthropic API key](https://console.anthropic.com) (per-user — entered in app)

### 2. Supabase setup

1. Create a new Supabase project
2. Go to **SQL Editor** and run `supabase/migrations/001_initial.sql`
3. Note your **Project URL** and **anon key** from Settings → API

Tables created: `invite_codes`, `profiles`, `user_settings`, `trips`, `trip_data`

Seed invite code **`TRIPPLAN2026`** is inserted automatically.

### 3. Local development

```bash
npm install
cp .env.example .env.local
# fill in NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY
npm run dev
```

### 4. Deploy to Vercel

```bash
npx vercel
# add the two env vars when prompted
```

### 5. Install on iPhone (PWA)

1. Open the URL in **Safari**
2. Tap Share → **Add to Home Screen**
3. App appears on home screen like a native app

---

## User roles

| Role | Claude API key | Create trips | View shared trips |
|------|---------------|-------------|------------------|
| Full | ✅ | ✅ | ✅ |
| Read-only | ❌ | ❌ | ✅ |

## Navigation priority

1. **Google Maps app** (`comgooglemaps://`) — if installed
2. **Apple Maps** (`maps://`) — built-in fallback
3. **Google Maps web** (`https://maps.google.com`) — universal fallback

## Invite codes

```sql
SELECT create_invite_code('SCOTLAND26', 90); -- valid for 90 days
```

## Tech stack

- **Next.js 14** App Router + React Server Components
- **Supabase** PostgreSQL + Auth + RLS
- **@supabase/ssr** server-side auth
- **Anthropic Claude** `claude-sonnet-4-6`, streaming SSE
- **Tailwind CSS** mobile-first, 44px touch targets
- **next-pwa** service worker + manifest
- **TypeScript** strict mode
