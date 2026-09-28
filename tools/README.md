# tools/

Small PowerShell scripts used to build and check the site's artwork. **None of them run on the
live site** — they only produce images and previews on your own machine. Run them from anywhere:

```powershell
powershell -ExecutionPolicy Bypass -File tools\climber-grid.ps1
```

They need nothing installed: they use `System.Drawing`, which ships with Windows.

## Why these exist

The rope-access climber that rides the scrollbar on `index.html` is drawn as SVG ropes **between
two layers of him** — `images/man-body.png`, then the ropes, then `man-front.png` (his descender
and his brake glove, the only two places a front rope ends). Everything about the ropes is
measured **in the man's own pixels**; fractions hide which black line you are actually aiming at.

These scripts are how those numbers get measured and checked without guessing.

## Building the climber

The owner draws the figure and its hardware as **separate pieces on one transparent sheet**
(`Desktop\try.png`). That is the whole trick: gear that is drawn into the figure has to have the
ropes bent to reach it, and two drawings were rejected that way. Loose gear gets placed on the
ropes instead.

| Script | What it does |
| --- | --- |
| `climber-parts.ps1` | Labels the separate blobs of ink on the sheet and reports each one's box. Writes each part out as its own PNG with `-OutDir`. Nothing is placed. |
| `climber-compose.ps1` | Places them and writes `images/man-body.png` + `man-front.png`. **Solves** the ASAP's position from the header mark's two rope stems, then stretches and leans the absorber to reach it, so both ropes stay plumb. Prints the numbers for `index.html`'s `A` table, and refuses to write unless restacking the two layers reproduces the composed figure exactly. |

## Measuring and checking the climber

| Script | What it does |
| --- | --- |
| `climber-grid.ps1` | A marking sheet: the live figure with its ropes, under a grid in the shipped layers' own pixels, with the current attachment points ringed. Send it to whoever is deciding and let them mark where a rope should go. → `Downloads\climber-grid.png` |
| `climber-grid.ps1` | Draws `climber.png` with a 0.01 grid over it, plus the ropes at their current positions. Send it to whoever is deciding, let them mark a spot. → `Downloads\climber-grid.png` |
| `climber-zoom-descender.ps1` | Big zoom on the descender with fine gridlines, for reading off exactly where a black outline crosses the rope. |
| `climber-zoom-glove.ps1` | The same for the brake hand, with the strand's own edges drawn as guides. |
| `climber-zoom-brake.ps1` | The brake fist with a grid in **artwork pixels**, which is the format to quote measurements in. |
| `climber-preview.ps1` | Reproduces what the browser paints — back ropes, then the figure, then front ropes, each clipped along its device outline — and crops/zooms it. Use this to *look* at a change before touching `index.html`. |
| `climber-compare-tip.ps1` | Renders the same rope end at several cut heights side by side, so one round of "A, B or C?" replaces three guesses. |

## Swapping a piece of gear in the artwork

| Script | What it does |
| --- | --- |
| `icon-to-lineart.ps1` | Turns a flat icon into `climber.png`'s line style: the icon's detail lines are usually *transparent gaps*, so a morphological closing seals them, paints them black, and adds a contour. |
| `climber-place-device.ps1` | Erases the old device from `climber.png` and drops the line-art one in its place. Writes `images/climber-newdevice.png` — the original is never touched. |

## The join.html wallpaper

`join-wallpaper.ps1` bakes the repeating tile behind the application form, from an icon folder
(currently `Desktop\icons` — change `$SRC` at the top). It:

- traces solid silhouettes into outlines, so every doodle is in one line style;
- sizes each one on the **geometric mean** of width and height (a flat icon like a headlamp is not
  left looking tiny) times how big the thing is **in real life** — see the `$RealSize` table, which
  is where a carabiner is told it is smaller than a harness;
- scatters them freely with a minimum spacing rather than on a grid, each at its own small tilt,
  and redraws anything crossing an edge on the opposite side so the tile still repeats seamlessly;
- bakes two versions, dark ink for the light theme and light ink for the dark one.

```powershell
powershell -ExecutionPolicy Bypass -File tools\join-wallpaper.ps1 `
  -Cols 8 -Rows 7 -Seed 105 -Target 74 -Tile 768 -Tilt 11 -Ver v9
```

Then point `join.html`'s two `background-image` rules at the new pair and bump the `?v=` on them,
or the browser keeps showing the old tile.

## A warning worth keeping

PowerShell variable names are **case-insensitive**: `$S` and `$s` are the same variable, as are
`$T` and `$t`, and `$Out` and `$out`. Three separate bugs in these scripts came from exactly that —
a loop counter silently overwriting the tile size. If a script suddenly draws nothing, look there
first.
