# EasyBite 🍽️

A monthly meal planner with recipes, BiteScore ratings, an ingredient pantry and a smart
shopping list. Single-file, vanilla JS, no build step — everything lives in `index.html`
and state is saved in the browser's `localStorage`.

Live on: <https://easy-bite.matija-jeras64.workers.dev>

## Features
- **Plan** – monthly calendar, one lunch per day; drag meals between days (mouse + touch).
  Past days are dimmed.
- **Recipes** – create/edit dishes; rate each on Ease, Taste & Health (1–10) which combine
  into a weighted **BiteScore** (0.2·Ease + 0.3·Taste + 0.5·Health).
- **Ingredients** – your ingredient catalog; add/edit/delete ingredients, pick a per-ingredient
  Nutri-Score manually or auto-suggest it from [Open Food Facts](https://openfoodfacts.org).
- **Shopping** – add a planned day's ingredients (all at once or one by one), tick items off
  as you shop, and drag category headers to match each store's aisle order.
- **EN / SLO** localization and light / dark themes.
- **Installable PWA** – works offline once loaded; "Add to Home Screen" on mobile.
- **Backup / restore** – export/import your data as a file or text (no account).
- **Accounts & households** – sign in and share one plan, recipe book and shopping list with
  your household; changes show up live on everyone's phone (works offline too, syncs later).

## Run locally
It's a static site — any static server works. For example:

```bash
python -m http.server 8123
# then open http://localhost:8123/
```

## Deploy (free)
Deploy the **whole folder** (needs `index.html`, `sw.js`, `manifest.webmanifest`,
`icon-*.png`). HTTPS is required for install + the Open Food Facts lookup — all of these
give it to you free:

- **Netlify** – drag the folder onto <https://app.netlify.com/drop>.
- **Cloudflare Pages / GitHub Pages** – push this repo and point the host at it
  (framework preset: *None*, build command: *empty*, output dir: `/`).

## Accounts & households (Supabase, free tier)
Without setup the app runs fully local. To enable sign-in and shared households:

1. Create a free project at <https://supabase.com> (the free tier is plenty).
2. **SQL Editor → New query** → paste the contents of [`supabase/schema.sql`](supabase/schema.sql) → **Run**.
3. **Authentication → URL Configuration**: set **Site URL** to your app URL
   (e.g. `https://easy-bite.matija-jeras64.workers.dev`) and add `https://<your-app>/**`
   to **Redirect URLs** (used by the confirmation email and invite links).
   *Optional:* **Authentication → Providers → Email → turn off "Confirm email"** if you
   don't want new users to confirm their address first.
4. **Project Settings → API**: copy the **Project URL** and the **anon public** key into
   `SUPABASE_URL` / `SUPABASE_ANON_KEY` at the top of the accounts section in `index.html`,
   then deploy.

**Optional — invite-only sign-ups:** run [`supabase/allowlist.sql`](supabase/allowlist.sql) with
your own email addresses filled in. Only listed emails can create an account; add more later with
`insert into public.signup_allowlist values ('someone@example.com');`.

In the app: **⋯ → Account** → create an account → **Create a group** → **Share invite**.
Anyone who opens the invite link (or enters the code) and signs in joins the household.

How it works: every recipe, planned day, shopping-list item, custom ingredient and store is a
row in one `entries` table, scoped to a group. Row-level security lets only group members read
or write it, so the URL and anon key are safe to publish. Each device keeps an offline copy
and an outbox of unsent changes; realtime updates keep everyone in sync.

> Note: free Supabase projects pause after about a week without any activity and wake up
> on the next request (the first load may take a few seconds).
