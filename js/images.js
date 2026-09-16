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
   Ordered so the carousel opens on the strongest ones. */
var galleryImages = [
  { file: "facade-tower.jpg",    full: "full/facade-tower.jpg",    en: "Facade cleaning",             ka: "ფასადის წმენდა" },
  { file: "facade-glass.jpg",    full: "full/facade-glass.jpg",    en: "Glass facade cleaning",       ka: "მინის ფასადის წმენდა" },
  { file: "window-cleaning.jpg", full: "full/window-cleaning.jpg", en: "Window cleaning",             ka: "მინების წმენდა" },
  { file: "height-window.jpg",   full: "full/height-window.jpg",   en: "Working at height",           ka: "სამუშაო სიმაღლეზე" },
  { file: "facade-inside.jpg",   full: "full/facade-inside.jpg",   en: "Facade works",                ka: "ფასადის სამუშაოები" },
  { file: "vardzia-rock.jpg",    full: "full/vardzia-rock.jpg",    en: "Rock stabilization — Vardzia", ka: "კლდის გამაგრება — ვარძია" },
  { file: "rock-slope.jpg",      full: "full/rock-slope.jpg",      en: "Rock & slope protection",     ka: "კლდეები, ფერდობები და გარემო" },
  { file: "bridge-clean.jpg",    full: "full/bridge-clean.jpg",    en: "Bridge cleaning",             ka: "ხიდის წმენდა" },
  { file: "structure-work.jpg",  full: "full/structure-work.jpg",  en: "Work on structures",          ka: "კონსტრუქციებზე მუშაობა" },
  { file: "install-height.jpg",  full: "full/install-height.jpg",  en: "Installation at height",      ka: "სამონტაჟო სამუშაოები სიმაღლეზე" },
  { file: "telecom-mast.jpg",    full: "full/telecom-mast.jpg",    en: "Telecom mast works",          ka: "ელექტროობა და ტელეკომუნიკაცია" },
  { file: "waterproofing.jpg",   full: "full/waterproofing.jpg",   en: "Waterproofing & sealing",     ka: "ჰიდროიზოლაცია" },
  { file: "chimney-flue.jpg",    full: "full/chimney-flue.jpg",    en: "Chimney & flue installation", ka: "საკვამურის მონტაჟი" },
  { file: "team-portrait.jpg",   full: "full/team-portrait.jpg",   en: "Our team",                    ka: "ჩვენი გუნდი" },
];
