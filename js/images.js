/* =====================================================================
   GALLERY PHOTOS  —  THIS IS THE FILE YOU EDIT TO ADD PICTURES
   =====================================================================

   To add a new photo to the carousel on the home page:

     1. Put your photo file inside the folder:   images/gallery/
        (use .jpg, .png or .webp — keep names simple, no spaces,
         e.g.  facade-tbilisi.jpg )

     2. Add ONE new line in the list below. Copy an existing line,
        paste it, and change the file name + captions.

           { file: "facade-tbilisi.jpg", en: "Facade cleaning", ka: "ფასადის წმენდა" },

        - file = the exact file name you put in images/gallery/
        - en   = caption shown in English
        - ka   = caption shown in Georgian

     3. Save this file and refresh the website. Done!

   OPTIONAL — a bigger version for the click-to-enlarge view:

        { file: "facade.jpg", full: "full/facade.jpg", en: "…", ka: "…" },

     Put the untouched original in  images/gallery/full/  and name it in `full`.
     The carousel frame is landscape, so a phone photo has to be cropped to fit
     it; `full` is what a visitor sees when they click — the whole picture, as
     it was taken. Leave `full` out and clicking simply enlarges `file`.

   To REMOVE a photo, just delete its line.
   Tip: photos look best at around 1200 x 800 pixels (landscape).
   ===================================================================== */

/* var, not const, and it has to stay var. index.html builds the slides from
   window.galleryImages, and in a plain <script> a top-level const creates a global BINDING
   without creating a property on window — so with const the check there is false and the
   carousel is built with no slides at all. */
/* All of these are the company's own job photographs — there are no placeholders left. The
   carousel shows a landscape frame, so anything shot upright was cut to the band its subject is
   actually in rather than to the middle of the frame; `full` is always the whole picture.
   Ordered so the carousel opens on the strongest one and then KEEPS ALTERNATING between the
   kinds of job — rock/cliff, glass tower, interior window, steelwork, building detail. Two
   photos that look alike (the two Vardzia shots, the two red-suit window shots taken through
   the same glass, the two blue-glass towers) are deliberately kept far apart, so slide after
   slide never shows the same picture twice. The list also loops, so the LAST entry sits next
   to the first — check that pair too when reordering. */
var galleryImages = [
  { file: "vardzia-cliff.jpg",     full: "full/vardzia-cliff.jpg",     en: "Climbing the Vardzia cliff",       ka: "კლდეზე მუშაობა — ვარძია" },
  { file: "tower-corner.jpg",      full: "full/tower-corner.jpg",      en: "Tower facade cleaning",            ka: "კოშკის ფასადის წმენდა" },
  { file: "window-inside.jpg",     full: "full/window-inside.jpg",     en: "Window cleaning, city view",       ka: "მინის წმენდა — ქალაქის ხედი" },
  { file: "bridge-clean.jpg",      full: "full/bridge-clean.jpg",      en: "Bridge cleaning",                  ka: "ხიდის წმენდა" },
  { file: "rock-slope.jpg",        full: "full/rock-slope.jpg",        en: "Rock & slope protection",          ka: "კლდეები, ფერდობები და გარემო" },
  { file: "chimney-flue.jpg",      full: "full/chimney-flue.jpg",      en: "Chimney & flue installation",      ka: "საკვამურის მონტაჟი" },
  { file: "cliff-river.jpg",       full: "full/cliff-river.jpg",       en: "Descending a cliff above the river", ka: "დაშვება კლდეზე მდინარის თავზე" },
  { file: "highrise-facade.jpg",  full: "full/highrise-facade.jpg",   en: "High-rise facade",                 ka: "მაღალსართულიანი ფასადი" },
  { file: "ridge-rigging.jpg",     full: "full/ridge-rigging.jpg",     en: "Rope rigging on a mountain ridge", ka: "თოკის სისტემა მთის ქედზე" },
  { file: "telecom-mast.jpg",      full: "full/telecom-mast.jpg",      en: "Telecom mast works",               ka: "ელექტროობა და ტელეკომუნიკაცია" },
  { file: "glass-tower-team.jpg",  full: "full/glass-tower-team.jpg",  en: "Team cleaning a glass tower",      ka: "გუნდი მინის კოშკის ფასადზე" },
  { file: "window-cleaning.jpg",   full: "full/window-cleaning.jpg",   en: "Window cleaning",                  ka: "მინების წმენდა" },
  { file: "vardzia-monastery.jpg", full: "full/vardzia-monastery.jpg", en: "Rope access at Vardzia monastery", ka: "სამუშაო ვარძიის კლდის ეკლესიაზე" },
  { file: "window-inside-2.jpg",   full: "full/window-inside-2.jpg",   en: "High-rise window cleaning",        ka: "მაღალსართულიანი მინის წმენდა" },
  { file: "structure-work.jpg",    full: "full/structure-work.jpg",    en: "Work on structures",               ka: "კონსტრუქციებზე მუშაობა" },
  { file: "cliff-descent.jpg",     full: "full/cliff-descent.jpg",     en: "Rope descent on a rock face",      ka: "თოკით დაშვება კლდის კედელზე" },
  { file: "waterproofing.jpg",    full: "full/waterproofing.jpg",     en: "Waterproofing & sealing",          ka: "ჰიდროიზოლაცია" },
];
