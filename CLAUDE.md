# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Bilingual (English/Georgian) marketing website for **Oritoki** (LTD Oritoki / შპს ორითოკი), an
industrial-climbing / works-at-height company. Two pages: `index.html` (the one-page site) and
`join.html` (the "Join our network" application form). Plain static site — **no framework, no build
step, no package manager, no test suite.**

## Running & checking

- **Preview:** open `index.html` or `join.html` directly in a browser (double-click). There is no
  dev server and nothing to build. An internet connection is needed: Tailwind, Swiper, Font Awesome
  and Google Fonts all load from CDNs.
- **JS syntax check:** most of the JavaScript now lives *inline* in the two HTML files, so
  `node --check` does not reach it. If Node is unavailable (it usually is on this machine), a brace
  and paren balance count over the file catches gross errors; otherwise verify by loading the page.
- **git is installed but not on PATH** — GitHub Desktop ships it:
  `C:\Users\<user>\AppData\Local\GitHubDesktop\app-<version>\resources\app\git\cmd\git.exe`.
  Committing from there works; `push`/`fetch` cannot authenticate from a non-interactive shell, so
  pushing is done by clicking **Push origin** in GitHub Desktop.
- **Artwork tooling lives in `tools/`** (PowerShell + System.Drawing, no install needed). See
  `tools/README.md`: grids and zooms for measuring the climber artwork, a preview that repaints what
  the browser draws, and the generator for the join-page wallpaper.

## Deployment

Domain `oritoki.ge` is bought; the host is not chosen yet (Cloudflare Pages connected to the GitHub
repo is the recommendation; Netlify Drop is the no-steps fallback). Whatever the host, deploy the
repo **contents** so that `public_html/index.html` — not a subfolder — is the site root.

## Architecture (the non-obvious parts)

**Both pages are self-contained.** `index.html` carries its own `<style>` and `<script>` blocks —
its theme tokens (`--c-night`, `--c-surface`, `--c-line`, …), its language switch, its nav, search,
service modals and the whole rope-climber system. `join.html` does the same for its own form.
The only shared files they load are `js/analytics.js`, `js/images.js` and `js/site-config.js`.

**`css/style.css` and `js/main.js` are NOT loaded by either page.** They are leftovers from an
earlier version; `README.md` still points at them in places. Do not edit them expecting a change on
the site — and do not delete them without checking `README.md` in the same pass.

**Bilingual text is attribute-driven, not template-driven.** Every translatable element holds the
English text as its normal content plus a `data-ka="..."` attribute with the Georgian. Each page's
own `applyLanguage(lang)`:
- captures the original English into `el.dataset.en` on first run (English is never authored twice),
- swaps `innerHTML` between `data-en` / `data-ka`,
- handles `<input>` placeholders separately via `data-ka-placeholder`,
- persists the choice in `localStorage["oritoki_lang"]` and labels the toggle with the *other*
  language. The theme is stored the same way in `localStorage["oritoki_theme"]`.

So **changing any wording means editing BOTH the visible English and its `data-ka` value.**

**Contact details live in one file.** `js/site-config.js` exports `siteInfo` (phone, e-mail,
address, socials); elements marked `data-si="tel|whatsapp|email|address|…"` are filled from it at
load, and the `tel:` / `wa.me` links are built from the phone number. Edit that file, not the
markup. There is **no contact form on `index.html`** — contact is by call, WhatsApp and e-mail. The
only form on the site is the application form on `join.html`.

**The gallery carousel is data-driven.** `js/images.js` exposes a global `galleryImages` array of
`{ file, en, ka }`. `index.html` builds the Swiper slides from it at load (sourcing
`images/gallery/<file>`), injects captions carrying `data-ka` so they translate, then initialises
Swiper. **Adding/removing carousel photos = editing `images.js` + dropping files into
`images/gallery/`** — the primary content workflow, documented for the owner in `README.md`. Swiper
`loop` clones slides at init (before `applyLanguage` runs), which is why language switching still
reaches cloned captions.

**The rope-access climber is the most intricate part of the site** (all of it inline in
`index.html`, near the bottom). He rides the scroll like a scrollbar thumb, on ropes drawn as SVG
over `images/climber.png`. What matters when touching it:

- **Measure in the artwork's own pixels.** Rope attachment points and the lines the ropes are cut
  along are read off `climber.png` at its native 560 × 686. Fractions hide *which* black line you
  are aiming at; several wrong guesses came from that. `tools/climber-grid.ps1` and the zoom scripts
  exist to take those measurements, and `tools/climber-preview.ps1` repaints what the browser draws
  so a change can be checked by looking at it rather than by reasoning about it.
- **The figure is one flat PNG**, so a rope is either wholly in front of it or wholly behind. A
  device's outline is made to pass in front of a rope by *cutting* the visible rope along that
  outline (`clip-path`, `applyCut`) and continuing it in the back layer.
- **Every body-anchored point goes through `bodyXY()`**, which applies the same sway *and lean*
  about the same pivot the browser uses on the image (`transform-origin: 50% 8%`). Translating alone
  makes the ropes drift out of his hands as soon as he leans.
- **He is a pendulum.** Range and rhythm both derive from the rope's length (`pendLen()`), swinging
  out lifts him (`pendRise()`), and letting go after a drag hands him to a damped spring. The rope
  ends are anchored to the **bottom of the page**, so they run off-screen while scrolling and only
  show their stopper knots in the footer.

**`join.html`'s background is a baked tile.** `images/join-doodles-{dark,light}-v12.png` (1536px,
displayed at 768) is generated by `tools/join-wallpaper.ps1` from `Desktop\icons`, which also holds
the wordmark as `oritoki-logo.png` — it is one of the doodles, and the only one drawn upright
(`$NoSpin`). Earlier passes (`-v3` … `-v8`) are kept in the repo as alternates. Regenerating means
bumping the `?v=` in `join.html` too, or browsers keep the old tile.

**The tile size is what controls how often an icon comes back.** It was 768 shown at 384, so the
whole pattern repeated every 384px across and down and one icon was on screen several times over.
It is 1536 shown at 768 now, and `$SameSpread` keeps two copies of one icon 0.30 of a tile apart,
measured with the wrap — on a tile that repeats, something near the left edge is next to the right
edge.

**Do not compute the doodle count, measure it.** Matching the old density on paper (25 per 768²
→ 100 per 1536²) came out visibly sparse; ink per *displayed* pixel put v8 at 7.8 and that tile at
3.6. The current one is 185 doodles at 8.2. `$ThinInk` / `$LineBoost` thicken any line icon below
26% coverage of its own box, because the supplied set mixes hairlines (dish, handshake, roller)
with much heavier drawings and at 6% opacity a hairline is not there at all.

The scatter is written longhand over typed arrays and picks the icon *before* throwing the dart.
The readable version — a helper function over hashtables, sorting all 42 icons at every throw —
did not finish a 200-doodle tile in ten minutes; this one takes seven seconds.

**The gallery is real photographs now** — fourteen of the company's own job pictures, listed in
`js/images.js`. Each entry also names a `full:` file in `images/gallery/full/`, the uncropped
original that the click-to-enlarge view opens; the carousel frame is landscape, so a photo shot
upright is cropped for the slide and only the `full` one is whole. The `sample-*.svg`
placeholders are still in `images/gallery/` but nothing references them. **Team images are still
placeholder SVGs** (`images/team/member-*.svg`) awaiting real photos. The hero and About images
are real (`hero-photo.jpg`, `about.jpg`).

## Conventions

- Brand renders as `ORITOKI` (EN) / `ორითოკი` (KA); the legal form `Oritoki LTD` / `შპს ორითოკი`
  appears only in the footer. There is no logo in the header — it was removed deliberately.
- Phone and address in `js/site-config.js` are the company's real ones. `info@oritoki.ge` is the
  intended address but **has no mailbox yet** — static hosting provides none.
- PowerShell variable names are case-insensitive (`$T` and `$t` are the same variable). That bit the
  `tools/` scripts three times; suspect it first when one of them silently draws nothing.

## Known pre-launch gaps

Verified against the files, not from memory — re-check before quoting:

1. **Tailwind Play CDN** (`cdn.tailwindcss.com`) is used by both pages. It is a dev-only tool that
   ships ~400 KB of JS and generates the CSS in the browser on every visit.
2. **Supabase keys** in `join.html` are still `YOUR_SUPABASE_URL` / `YOUR_SUPABASE_ANON_KEY`, so the
   application form saves nothing. `supabase-setup.sql` is ready in the repo.
3. **Google Analytics** — `js/analytics.js` still holds `G-XXXXXXXXXX` and stays inert until a real
   GA4 ID is pasted in.
4. **`emblem.png` is 504 KB** and `join.html` shows it 36 px tall — worth shrinking.
5. `404.html` exists and works as-is on Netlify / Cloudflare Pages. On Apache (cPanel) it needs
   `ErrorDocument 404 /404.html` in an `.htaccess`.

Done and not to be redone: Open Graph / Twitter tags and `<link rel="canonical">` on both pages
(share image `images/og-image.jpg`, 1200×630 — regenerate from `hero-photo.jpg` if the hero
changes), `404.html`, and the removal of ~4.4 MB of unreferenced images. `robots.txt` and
`sitemap.xml` exist and already reference `https://oritoki.ge`; if the live site ends up on `www.`,
both files **and the absolute URLs in the OG tags** need the domain updated.
