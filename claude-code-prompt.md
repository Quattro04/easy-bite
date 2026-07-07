Build a single-file web app called **EasyBite** — a weekly meal planner with recipes, pantry tracking, a self-learning shopping list, Nutri-Scores, EN/SLO localization, and light/dark themes. One `index.html` file, vanilla JS, no frameworks, no build step, state persisted in `localStorage`.

## Core loop
Plan meals for the week → app computes missing ingredients (needed minus pantry stock) → shopping list → ticking an item marks it bought AND adds its quantity to the pantry (unticking reverses this) → pantry is the single source of truth for "what's in the kitchen."

## Data model (in-memory state object, saved to localStorage on every change)
- `Ingredient { id, name:{en,sl}, cat, unit, g (grams per unit, for weighting), ns (Nutri-Score letter A–E) }`
- Categories: vegetables, fruit, dairy, meat, grains, pantry (staples), sweets, drinks — each with a label in both languages and an emoji.
- `pantry`: map ingredientId → quantity currently at home.
- `Recipe { id, name:{en,sl}, servings, items:[{ing, q}] }`
- `plan`: map "Day-Meal" (e.g. "Mon-Dinner") → recipeId. Days Mon–Sun, meals Breakfast/Lunch/Dinner.
- `manual`: manually added shopping items `[{ing, q}]`.
- `ticked`: map ingredientId → quantity ticked this shopping session.
- `stores`: `[{ id, name, order: {category → position number} }]`, plus `storeId` (active store) and `session` (array of categories in first-tick order for the current trip).

## Features

### 1. Week view (default)
7-day grid × 3 meal slots. Empty slot = dashed "+" card; click opens a modal listing all recipes (with score badges) to assign, or clear the slot. Filled slot shows meal label, dish name, and its Nutri-Score badge. Top bar shows: week score (average of planned dishes), number of planned meals, count of ingredients to buy, and a button to jump to the shopping list.

### 2. Recipes view
Card grid; each card shows name, score badge, ingredient/serving counts, and an availability chip: green "✓ all in kitchen" or red "N missing" (missing = pantry qty < recipe qty). "New recipe" and click-to-edit open a modal: name, servings, ingredient rows (dropdown from catalog + quantity + unit label, removable, addable), live score badge in the title, save/delete.

### 3. Pantry ("Kitchen") view
Ingredients grouped by category (emoji + label headers). Each row: score badge, name, quantity + unit, and −/+ stepper buttons (step 50 for g/ml, 1 otherwise; never below 0).

### 4. Shopping list view
- Auto-derived: for every planned meal sum required quantities per ingredient, add manual items, subtract pantry stock (excluding this session's ticks); positive remainder appears on the list. Ticked items stay visible (struck through, sunk to the bottom of their group) until "Finish trip" clears them.
- Ticking adds the quantity to the pantry; unticking removes it again.
- Store selector dropdown (seed two stores with opposite category orders, e.g. "Spar Center" and "Lidl Vič"). Progress bar showing ticked/total. Manual "Add item" modal (ingredient + quantity). Nav tab shows a badge with the count of unticked items.
- **Learned walk order:** groups are sorted by the active store's `order` values. During a trip, record the sequence in which categories receive their *first* tick; on each first tick update `order[cat] = 0.7 × old + 0.3 × observedRank` (or just the rank if the category is new). Never-seen categories sort last, alphabetically. Show "stop 1, stop 2…" tags on group headers and a tip explaining the learning. Switching store or finishing a trip resets the session.

### 5. Nutri-Score
Letters map to values A=100, B=75, C=50, D=25, E=0. A dish's score is the gram-weighted average of its ingredients' values (quantity × gramsPerUnit), mapped back: A ≥ 80, B ≥ 60, C ≥ 40, D ≥ 20, else E. Week score = plain average of planned dish values. Badges: small rounded squares colored dark green / light green / yellow / orange / red.

### 6. Localization (EN/SLO)
All UI strings from a translation dictionary; default language Slovenian. Header toggle showing both "EN | SLO" with the active one highlighted. Translate everything: nav, headings, buttons, modals, tips, empty states, day abbreviations (Pon, Tor, Sre, Čet, Pet, Sob, Ned), meals (Zajtrk, Kosilo, Večerja), categories (Zelenjava, Sadje, Mlečni izdelki, Meso in ribe, Žita in testenine, Osnovna živila, Sladkarije in prigrizki, Pijače), units (pcs→kos, can→konz.), and the sample data itself — ingredient and recipe names are `{en, sl}` objects. User-created recipe names apply to both languages. Set `document.documentElement.lang` accordingly.

### 7. Themes
Light (default) and dark, toggled by a 🌙/☀️ header button, implemented purely with CSS custom properties switched via `body[data-theme="dark"]`. Both language and theme persist in localStorage.

## Design
Flat and clean, mobile-friendly: near-white background (#fafafa) / dark #121215; white / #1c1c21 cards with 1px hairline borders and 12–14px radius — **no shadows, no gradients**; one warm accent #FF6B4A (slightly brighter in dark mode) used for active nav pill, primary buttons, checkboxes, progress bar; system font stack; sticky header with logo "Easy**Bite**" (accent on "Bite"); pill-shaped nav; generous touch targets; subtle transitions on hover/tick. Nutri colors: #1e8f4e, #7cb342, #f6c344 (dark text), #f08c2e, #e5484d.

## Seed data
~22 ingredients across all 8 categories with realistic units, gram weights, and Nutri-Scores (e.g. Tomatoes/Paradižnik A, Milk/Mleko B, Mozzarella C, Minced beef/Mleto goveje meso D, Honey/Med D, Dark chocolate/Temna čokolada D). 5 recipes with bilingual names: Spaghetti Bolognese/Špageti po bolonjsko, Salmon & Rice Bowl/Losos z rižem, Banana Oat Breakfast/Ovseni zajtrk z banano, Caprese Salad/Solata caprese, Chicken Stir-fry/Piščanec z zelenjavo iz voka. A pre-filled week plan (~7 meals) and partial pantry stock so the shopping list is non-empty on first load.

## Architecture & quality
Single state object + one `render()` that re-renders the active view; simple template literals for HTML; modals via a single overlay container; guard `localStorage` access with try/catch. Verify before finishing: no console errors on load; tick→pantry→untick round-trips exactly; recipe create/edit/delete updates plan and list; store order visibly changes after ticking in a new sequence; every view renders correctly in both languages and both themes with no "undefined" in the DOM.
