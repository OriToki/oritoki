# Oritoki — Height Works Website

A simple, free, one-page website for a works-at-height / industrial-climbing
company. Built with plain HTML, CSS and JavaScript — **no installation, no build
tools, no monthly fees.**

Sections: **Home · About · Services · Gallery (photo carousel) · Team · Contact**
Languages: **English + Georgian** (switch with the button in the top-right).

---

## 1. How to open it on your computer

Just **double-click `index.html`** — it opens in your web browser. That's it.

---

## 2. How to add or change carousel photos  ⭐ (the main thing)

1. Put your photo files into the **`images/gallery/`** folder.
   - Use `.jpg`, `.png` or `.webp`
   - Simple names, no spaces — e.g. `facade-tbilisi.jpg`
   - Best size: about **1200 × 800 pixels** (landscape)

2. Open **`js/images.js`** in Notepad (or any text editor) and add one line per
   photo. Copy an existing line and change the file name and captions:

   ```js
   { file: "facade-tbilisi.jpg", en: "Facade cleaning", ka: "ფასადის წმენდა" },
   ```

3. **Save** the file and **refresh** the website. Done!

To remove a photo, delete its line. The example `sample-1.svg … sample-6.svg`
placeholders can be deleted once you add your real photos.

---

## 3. How to change text (name, slogan, services…)

Open **`index.html`** in a text editor. For every piece of text you'll see two
versions:

```html
<h3 data-ka="ფასადის წმენდა">Facade &amp; Window Cleaning</h3>
```

- The normal text (`Facade & Window Cleaning`) is the **English** version.
- The text inside `data-ka="..."` is the **Georgian** version.

Edit **both** to change a wording.

---

## 4. How to change phone, email, address & social links

In **`index.html`**, find the **CONTACT** section and the **FOOTER**:

- Phone: `tel:+995500000000` → put your real number (twice: the link and the text)
- WhatsApp: `https://wa.me/995500000000`
- Email: `mailto:info@oritoki.ge`
- Address text: `Tbilisi, Georgia`
- Facebook / Instagram / TikTok: replace the `href="#"` with your page links

### Make the contact form send you emails (free, optional)
1. Sign up free at **https://formspree.io**
2. It gives you a form address like `https://formspree.io/f/abcwxyz`
3. In `index.html` find `action="https://formspree.io/f/YOUR_ID"` and replace
   `YOUR_ID` with yours.

Until you do this, the phone / WhatsApp / email links already work fine.

---

## 5. How to put it online for FREE

Pick any one of these (all have free plans and give you a web address):

**Easiest — Netlify Drop**
1. Go to **https://app.netlify.com/drop**
2. Drag the whole `misho` folder onto the page.
3. You instantly get a link like `your-site.netlify.app`. To update, drag again.

**Cloudflare Pages** — https://pages.cloudflare.com (similar, free)

**GitHub Pages** — free if you keep the files in a GitHub repository.

You can later connect your own domain (e.g. `oritoki.ge`) in the host's settings.

---

## 6. Change the colors / company name

- **Colors:** open `css/style.css`, edit the values at the very top under
  `:root` (e.g. `--orange` is the main accent color).
- **Company name "Oritoki":** search for `ORITOKI` in `index.html` and replace it.
- **Logo:** replace `images/logo.svg` with your own logo (keep the same name).

---

## File overview

```
misho/
├── index.html          ← the page + all text (English + Georgian)
├── css/style.css       ← colors, fonts, layout
├── js/
│   ├── images.js       ← THE PHOTO LIST you edit to add carousel pictures
│   └── main.js         ← menu, language switch, carousel (rarely edited)
├── images/
│   ├── gallery/        ← put carousel photos here
│   ├── team/           ← team member photos
│   ├── hero.svg        ← big background image on the home screen
│   ├── about.svg       ← picture in the About section
│   └── logo.svg        ← logo
└── README.md           ← this guide
```

The carousel uses [Swiper](https://swiperjs.com), icons by
[Font Awesome](https://fontawesome.com), fonts by Google Fonts — all free and
loaded automatically from the internet (so keep the computer online when viewing).
