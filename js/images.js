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

   To REMOVE a photo, just delete its line.
   Tip: photos look best at around 1200 x 800 pixels (landscape).
   ===================================================================== */

const galleryImages = [
  { file: "sample-1.svg", en: "Facade cleaning",        ka: "ფასადის წმენდა" },
  { file: "sample-2.svg", en: "Painting at height",     ka: "შეღებვა სიმაღლეზე" },
  { file: "sample-3.svg", en: "Window washing",         ka: "ფანჯრების წმენდა" },
  { file: "sample-4.svg", en: "Waterproofing & sealing", ka: "ჰიდროიზოლაცია" },
  { file: "sample-5.svg", en: "Sign installation",      ka: "რეკლამის მონტაჟი" },
  { file: "sample-6.svg", en: "Roof maintenance",       ka: "სახურავის მოვლა" },
];
