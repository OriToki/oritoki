# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Bilingual (English/Georgian) one-page marketing website for **Oritoki** (LTD Oritoki / შპს ორითოკი), an industrial-climbing / works-at-height company. Plain static site — **no framework, no build step, no package manager, no test suite.**

## Running & checking

- **Preview:** open `index.html` directly in a browser (double-click). There is no dev server or build. An internet connection is required because Swiper, Font Awesome and Google Fonts load from CDNs.
- **JS syntax check:** `node --check js/main.js` and `node --check js/images.js`.
- **Rebuild the deploy ZIP** (Windows PowerShell) — produced on the Desktop, one level above the repo:
  ```powershell
  Compress-Archive -Path "c:\Users\giorg\OneDrive\Desktop\misho\*" -DestinationPath "c:\Users\giorg\OneDrive\Desktop\misho-website.zip" -Force
  ```

## Deployment

Target is cheap cPanel shared hosting from a Georgian (.ge) provider. Deploy by uploading the repo **contents** into `public_html` so that `public_html/index.html` exists — NOT inside a `misho/` subfolder, or the site loads under `/misho/`. `misho-website.zip` is the upload artifact (extract it in `public_html`). The same folder also drag-and-drop deploys to free hosts (Netlify Drop / Cloudflare Pages).

## Architecture (the non-obvious parts)

**Bilingual text is attribute-driven, not template-driven.** Every translatable element holds the English text as its normal content plus a `data-ka="..."` attribute with the Georgian. `js/main.js` `applyLanguage(lang)`:
- captures the original English into `el.dataset.en` on first run (English is never authored twice),
- swaps `innerHTML` between `data-en` / `data-ka`,
- handles `<input>` placeholders separately via `data-ka-placeholder`,
- persists the choice in `localStorage["oritoki_lang"]` and sets the toggle label to the *other* language.

So **changing any wording means editing BOTH the visible English and its `data-ka` value.** Georgian currently renders through system-font fallback (Oswald/Inter carry no Georgian glyphs).

**The gallery carousel is data-driven.** `js/images.js` exposes a global `galleryImages` array of `{ file, en, ka }`. `main.js` builds the Swiper `.swiper-slide`s from it at load (sourcing `images/gallery/<file>`), injects captions carrying `data-ka` so they translate, then initializes Swiper. **Adding/removing carousel photos = editing `images.js` + dropping files into `images/gallery/`** — this is the primary content workflow and is documented for the non-technical owner in `README.md`. Swiper `loop` clones slides at init (before `applyLanguage` runs), which is why language switching still reaches cloned captions.

**Theming is centralized** in CSS custom properties under `:root` in `css/style.css` (`--orange` is the brand accent). The page is a sticky-header single-scroll layout; `main.js` also drives IntersectionObserver-based active-nav highlighting, `.reveal` scroll-in animations, and the mobile burger menu.

**All images are placeholder SVGs** (`images/gallery/sample-*.svg`, `images/team/member-*.svg`, `hero.svg`, `about.svg`, `logo.svg`) intended to be swapped for real photos. `logo.svg` is a "two ropes twisted together" mark — the literal meaning of *Oritoki* (ori = two, toki = rope); preserve that concept if regenerating it.

## Conventions

- Brand renders as `ORITOKI` (EN) / `ორითოკი` (KA); the legal form `Oritoki LTD` / `შპს ორითოკი` appears only in the footer.
- The contact form posts to Formspree — its `action` still contains a `YOUR_ID` placeholder to be replaced; the `tel:` / `mailto:` / WhatsApp links work with no setup.
- Contact details (`info@oritoki.ge`, `+995 500 00 00 00`, team member names) are dummy placeholders awaiting the owner's real information.
