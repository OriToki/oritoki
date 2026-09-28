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
between two layers of him. What matters when touching it:

- **The figure is COMPOSED, not cut up.** The owner drew `Desktop\try.png` as three separate
  pieces on one transparent canvas — the man with his descender, the absorber with its carabiner
  and swivel, and the ASAP **with a real hole in it**. `tools/climber-parts.ps1` labels them,
  `tools/climber-compose.ps1` places them and writes `images/man-body.png` + `man-front.png`
  (760 × 856). **This is why it finally works.** Two finished drawings with their gear drawn in
  were cut up before this and both were rejected: when the hardware is fixed in the drawing, the
  ropes have to be bent to reach it. With the gear separate, the ASAP is *placed* on the rope and
  the absorber is stretched and leaned to reach the ASAP.
- **The one thing nothing can change** is the gap between the two ropes: they hang from the two
  stems of the header mark, 0.12359 of the strip apart. `climber-compose.ps1` **solves** the
  ASAP's position from that (`$SEP`), so both ropes are dead plumb and neither device was shoved
  sideways — a first.
- **Two layers, and only two pieces in the front one:** `man-body.png` under the ropes,
  `man-front.png` (the RIG with its carabiner, and the brake glove) over them. Those are the only
  places a front rope ENDS. **Nothing else may be lifted into the front layer** — the owner asked
  for the working rope to run in front of all the rest of him, absorber and gripping fist
  included, and putting the fist up there is the version he rejected: the rope vanished behind
  his hand a third of the way down instead of running on to the device.
- **So every rope end is BURIED** a few pixels inside the ink that covers it, and there is no
  visible end to place at any angle. That replaced four `clipPath`s, a patch-cut solver and a
  hand-traced fist polygon — and with them the black spike the brake strand's cut kept drawing.
  **If an end ever shows, take the point deeper into the ink; do not bring the cuts back.**
- **The backup rope needs no piece at all.** It is painted in the back layer, behind everything,
  and the ASAP's hole lets it show through. Nothing cut, nothing clipped.
- **Measure in the shipped layers' own pixels** (760 × 856) or in the man's own (1097 × 1236,
  which is what `climber-compose.ps1` takes and prints). Fractions hide *which* black line you
  are aiming at; several wrong guesses came from that. `tools/climber-grid.ps1` draws a marking
  sheet of the live figure, and scratchpad `readmarks.ps1` reads the owner's coloured rings back
  off it by diffing — reading a 9 px ring by eye off a sheet shown at a third of its size is how
  you end up ten pixels out.
- **`images/climber.png` is the previous, flat figure** and nothing loads it any more. It is kept
  because two replacements were reverted onto it by hand when the working state had never been
  committed. **Commit before replacing the figure again.**
- **Every body-anchored point goes through `bodyXY()`**, which applies the same sway *and lean*
  about the same pivot the browser uses on the image (`transform-origin: 50% 8%`). Translating alone
  makes the ropes drift out of his hands as soon as he leans.
- **He is a pendulum.** Range and rhythm both derive from the rope's length (`pendLen()`), swinging
  out lifts him (`pendRise()`), and letting go after a drag hands him to a damped spring. The rope
  ends are anchored to the **bottom of the page**, so they run off-screen while scrolling and only
  show their stopper knots in the footer.

**The header mark is the owner's drawing, cut — never rebuilt.** `Desktop\parts\final logo.png` is
the finished lockup: "or" over "tok" with a bolt hanger, locking carabiner and knot standing in for
each dotted i. `tools/logo-split.ps1` cuts it into three layers that live in `#ropeClimber`:
`logo-work.png` and `logo-back.png` (a carabiner with its knot, each turning about the point where
it hangs) under `logo-rest.png` (the lettering and both hangers, z-4, over everything in the strip).

Before this the mark was *assembled* from separate pieces fitted back against that same finished
drawing, and it cost days. A fit can score well on every piece and still stack them wrong: it ended
with a rope loop lying on top of a carabiner instead of threaded through it, which no amount of
re-fitting fixed because nothing was mis-placed. So: **every pixel written out is a pixel of the
drawing**, the split is along the drawing's own outlines (flood-fill the light ink, each blob goes
whole to one layer), and the script refuses to be trusted on faith — it stacks the three with no
rotation and compares against the source before writing (currently 0 pixels differ, in alpha and in
colour). If that check ever reports a non-zero number, the cut is wrong; do not ship it.

**The split loses the bolt fill.** In the owner's drawing each hanger's hex bolt head is filled with
a solid grey — the same grey the rope is drawn in — but `logo-plate.png` came out with the hexagons
empty, so on the site the bolts read as hollow white dots. `tools/logo-bolt.ps1` puts the fill back,
darker, in both `logo-plate.png` and `logo-full.png`. It does **not** paint a flat colour: each bolt
is flood-filled from a seed, the region's own base lightness is measured (255 where the hexagon came
out white, ~155 where the owner's grey survived) and every pixel is scaled by `Target/Base`, so the
antialiased rim keeps its exact ramp and one script is correct on both files. The seeds came from
listing every enclosed light region, not from reading a zoom — the hexagons are 8 px across in
`logo-plate.png`. The script refuses to write if a flood exceeds 1500 px, which means the outline is
not closed and the fill has escaped. Re-running it means bumping the `?v=` on both files.

`A.pivotWork` / `A.pivotBack` are where the owner marked the two hinges on a printed grid of the
live page (`tools/page-grid.ps1` makes the grid; scratchpad `greendots.ps1` read his marks back).
`A.stemWork` / `A.stemBack` are where each cord ends and the SVG rope takes over, and they are held
as offsets *from the pivot* so they swing with the carabiner.

**`join.html`'s background is a baked tile.** `images/join-doodles-{dark,light}-v14.png` (1536px,
displayed at 768) is generated by `tools/join-wallpaper.ps1` from **`Desktop\icons in high rez`** —
60 icons at 1254², one per file. The earlier low-resolution set in `Desktop\icons` was retired at
the owner's request and every tile before `-v14` was deleted. Regenerating means bumping the `?v=`
in `join.html` too, or browsers keep the old tile.

**The tile copies a measured target, not an impression.** The owner's reference is the WhatsApp
chat wallpaper (`Desktop\background.png`). Measured off it: **tile 810px** (autocorrelation,
correlation 1.000), **ink 17.5%** of the tile, **icons 8.9%** of the tile side, all **upright**.
The generator prints its own three figures at the end of every run for exactly this comparison —
at 6% opacity the eye cannot judge density, and each pass that tried to instead of measuring got
it wrong. **The size figures are the one place we deliberately sit far below the reference** — the
owner asked four times for smaller icons, so v14 runs 1287 doodles at 1.3%–4.6% (2.3% median)
against the reference's typical 8.9%. That is about a quarter of the reference's icon size: at 768
display px the median doodle is ~17px on screen, which is texture more than drawing. It is what he
asked for and he has seen it at every step; do not quietly enlarge it. Settings:
`-Target 48 -Tight 0.85 -Big 300 -Mid 450 -Small 750 -Tries 1200 -Gap 2 -SameSpread 0.12`.

**`$SameSpread` has to come down as the count goes up**, and it is easy to miss because it fails
silently. It keeps two copies of one icon apart, so with 59 icons a tile can hold only about
`(1/SameSpread)²` of each before no legal spot is left. At 0.24 the passes jammed at 300/450 and
43/750 and the tile looked half-empty — nothing in the output says *why*, the counts just stop.
Dropping it to 0.12 with the same everything else took the same run from 617 doodles to 1287.

**One icon is excluded, by name, in `$Skip`.** The abseiler on the cliff
(`…12_41_07 PM (10).png`) is a solid black wedge filling most of its frame, and at wallpaper size
it read as a dark blob rather than a drawing — the owner circled it and asked for it out. The file
is still in his folder; deleting the line in `$Skip` brings it back.

**Three size passes are what fill the tile, and nothing may overlap.** Both rules come from the
owner, who marked up a tile where icons sat on top of each other and pointed at the reference:
*big drawings with little drawings tucked into the spaces between them*. So doodles go down in
three passes, largest first — `$Big` at `$Target`, `$Mid` at `$MidScale`, `$Small` at
`$SmallScale` — and each pass starts with a fresh "blocked" slate, because an icon that would not
fit at full size usually fits at 42%. The small pass is expected to jam before it places them all;
that is it running out of gaps, not a fault.

The collision test is **rectangle against rectangle on the axis-aligned box of the tilted doodle**,
so two doodles can sit edge to edge but never on top of one another. An earlier version measured
circles round each doodle and was told to let them interlock at 0.62 of their radii — that is
exactly what put icons on top of each other. `$Tight` shrinks each box a little before the test
(0.85), because a bounding box has empty corners and a shade under 1.0 lets two doodles tuck
together without their ink meeting; 1.0 keeps the boxes strictly apart and leaves the tile holey.
`$Tries` has to be generous (1500) or the small pass gives up long before the gaps are full.

**Everything leans.** `$Tilt` (22°) gives each doodle a random lean either way. Dead-upright stamps
were the owner's other complaint — the reference's cat leans left and its wheelchair leans right —
and the lean is what stops the field looking machine-printed. Keep it modest: the box is the AABB
of the *tilted* icon, so at 45° a long doodle reserves half again its own area in empty corner.

**The tile size is what controls how often an icon comes back.** It was 768 shown at 384, so the
whole pattern repeated every 384px across and down and one icon was on screen several times over.
It is 1536 shown at 768 now — close to the reference's 810 — and `$SameSpread` keeps two copies of
one icon 0.28 of a tile apart, measured with the wrap, since on a tile that repeats something near
the left edge is next to the right edge.

**Size is by pass, not by subject.** An earlier tile scaled each doodle by how big the thing is in
real life (a carabiner smaller than a pylon), off a hand-written `$RealSize` table keyed to
filenames the new set does not have. That is gone: a doodle's size now comes from which pass placed
it, plus a ±6% jitter. A carabiner can be the big one on this tile and a small one on the next,
which is how the reference behaves.

Two things in the loader earn their keep: solid-silhouette icons are **traced to outlines** so the
set is in one line style (mixing filled and outlined reads badly at wallpaper size), and the one
icon supplied **white-on-black** — the wordmark — is detected by its border luminance and flipped,
because traced as supplied it comes out a solid rectangle.

The scatter is written longhand over typed arrays and picks the icon *before* throwing the dart.
The readable version — a helper function over hashtables, sorting the whole set at every throw —
did not finish a 200-doodle tile in ten minutes.

It also files every doodle in a **12×12 bucket grid**, so a dart only tests the neighbours it could
actually reach instead of all of them. Testing every dart against every doodle is O(n) a throw, and
that stopped being affordable the moment the icons were made smaller and their number went up to
compensate — 470 doodles at 1300 tries is tens of millions of comparisons. Verified as a pure
optimisation: the same seed and settings before and after the change produced byte-identical
figures (ink 23.24%, sizes 5.26/11.19/3.05%). A whole run is about 30 seconds.

**The gallery is real photographs now** — fourteen of the company's own job pictures, listed in
`js/images.js`. Each entry also names a `full:` file in `images/gallery/full/`, the uncropped
original that the click-to-enlarge view opens; the carousel frame is landscape, so a photo shot
upright is cropped for the slide and only the `full` one is whole. The `sample-*.svg`
placeholders are still in `images/gallery/` but nothing references them. **Team images are still
placeholder SVGs** (`images/team/member-*.svg`) awaiting real photos. The hero and About images
are real (`hero-photo.jpg`, `about.jpg`).

## Conventions

- Brand renders as `ORITOKI` (EN) / `ორითოკი` (KA); the legal form `Oritoki LTD` / `შპს ორითოკი`
  appears only in the footer.
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
