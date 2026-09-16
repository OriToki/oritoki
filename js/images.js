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
var galleryImages = [
  /* Real photographs from the company's own jobs. They were shot upright on a phone and the
     carousel shows a landscape frame, so each was cut to the band its subject is actually in
     rather than to the middle of the frame. */
  { file: "window-cleaning.jpg", full: "full/window-cleaning.jpg", en: "Window cleaning",        ka: "მინების წმენდა" },
  { file: "waterproofing.jpg",   full: "full/waterproofing.jpg",   en: "Waterproofing & sealing", ka: "ჰიდროიზოლაცია" },
  { file: "rock-slope.jpg",      full: "full/rock-slope.jpg",      en: "Rock & slope protection", ka: "კლდეები, ფერდობები და გარემო" },
  { file: "telecom-mast.jpg",    full: "full/telecom-mast.jpg",    en: "Telecom mast works",      ka: "ელექტროობა და ტელეკომუნიკაცია" },
  /* Placeholders, waiting for a real photograph each. Delete a line as its photo arrives. */
  { file: "sample-1.svg", en: "Facade cleaning",        ka: "ფასადის წმენდა" },
  { file: "sample-2.svg", en: "Painting at height",     ka: "შეღებვა სიმაღლეზე" },
  { file: "sample-5.svg", en: "Sign installation",      ka: "რეკლამის მონტაჟი" },
  { file: "sample-6.svg", en: "Roof maintenance",       ka: "სახურავის მოვლა" },
];
