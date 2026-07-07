# EasyBite 🍽️

A monthly meal planner with recipes, an ingredient pantry, Nutri-Scores and a smart
shopping list. Single-file, vanilla JS, no build step — everything lives in `index.html`
and state is saved in the browser's `localStorage`.

## Features
- **Plan** – monthly calendar, one lunch per day; drag meals between days (mouse + touch).
  Past days are dimmed and drop out of the shopping list.
- **Recipes** – create/edit dishes with a live Nutri-Score badge and an "in stock" chip.
- **Ingredients** – your pantry catalog; add/edit/delete ingredients, pick a Nutri-Score
  manually or auto-suggest it from [Open Food Facts](https://openfoodfacts.org).
- **Shopping** – auto-derived from the plan minus what's in the pantry; tick items to add
  them to the pantry; drag category headers to match each store's aisle order.
- **EN / SLO** localization and light / dark themes.
- **Installable PWA** – works offline once loaded; "Add to Home Screen" on mobile.
- **Backup / restore** – export/import your data as a file or text (no account).
- **Optional cloud sync** – connect a free Firebase project to sync across devices.

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

## Optional: cloud sync setup (Firebase, free tier)
1. Create a project at <https://console.firebase.google.com> and add a **Web app**;
   copy the `firebaseConfig` snippet.
2. **Authentication → Sign-in method → Email/Password → Enable.**
3. **Firestore Database → Create**, then set **Rules** to:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /easybite/{uid} {
         allow read, write: if request.auth != null && request.auth.uid == uid;
       }
     }
   }
   ```
4. In the app: **⋯ menu → Cloud sync**, paste the config, create an account, and sign in
   with the same account on every device.

The Firebase config is safe to keep client-side — access is protected by the Auth rules above.
