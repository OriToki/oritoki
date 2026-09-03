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

## 4. How to change phone, email, address & social links  ⭐

Open **`js/site-config.js`** — everything lives in that one file:

```js
var siteInfo = {
  phone: "+995 571 25 35 30",
  email: "info@oritoki.ge",
  address: {
    en: "Address: Apt 23B, 13 E. Ninoshvili St., Tbilisi, Georgia",
    ka: "მისამართი: ე. ნინოშვილის ქ. 13, ბ. 23B, თბილისი, საქართველო"
  },
  social: {
    facebook:  "https://www.facebook.com/…",
    instagram: "https://www.instagram.com/…",
    tiktok:    ""
  }
};
```

Change a value **once** and it updates everywhere — contact section, footer, the
"call" link and the WhatsApp button. You never write the phone number twice: the
call and WhatsApp links are built from it automatically.

To **hide** a social icon (e.g. no TikTok account yet), leave it empty: `tiktok: "",`

> Don't edit the phone/email directly in `index.html` any more — those places are
> filled from this file, so your change there would be overwritten on load.

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
│   ├── site-config.js  ← THE CONTACT DETAILS (phone, e-mail, address, socials)
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

---

# 🇬🇪 მოკლე ინსტრუქცია (ქართულად)

ორი ყველაზე ხშირი საქმე — ფოტოს დამატება და კონტაქტების შეცვლა. **`index.html`-ს
ხელი არ უნდა ახლო არცერთ შემთხვევაში.**

## ფოტოს დამატება გალერეაში

**1.** ჩააგდე ფოტო საქაღალდეში `images/gallery/`

  - ფორმატი: `.jpg`, `.png` ან `.webp`
  - სახელი მარტივი, **ქართული ასოებისა და ხარვეზების გარეშე** — მაგ. `facade-vake.jpg`
  - სასურველი ზომა: დაახლოებით **1200 × 800** პიქსელი

**2.** გახსენი `js/images.js` და დაამატე **ერთი ხაზი**. დააკოპირე არსებული ხაზი და
შეცვალე ფაილის სახელი და წარწერები:

```js
{ file: "facade-vake.jpg", en: "Facade cleaning", ka: "ფასადის წმენდა" },
```

- `file` — ფაილის ზუსტი სახელი, რომელიც `images/gallery/`-ში ჩააგდე
- `en` — წარწერა ინგლისურ ვერსიაზე
- `ka` — წარწერა ქართულ ვერსიაზე

**3.** შეინახე ფაილი და გვერდი განაახლე. მზადაა.

ფოტოს წასაშლელად უბრალოდ წაშალე მისი ხაზი.

## ტელეფონის, ფოსტის ან მისამართის შეცვლა

გახსენი `js/site-config.js` — ყველაფერი იქაა:

```js
phone: "+995 571 25 35 30",
email: "info@oritoki.ge",
```

**ნომერი მხოლოდ ერთხელ იწერება.** დარეკვის ბმულიც და WhatsApp-იც ავტომატურად
აეწყობა — ორჯერ წერა არ გჭირდება. ფოსტაც ორივე ადგილას (კონტაქტში და ფუთერში)
თავისით განახლდება.

მისამართს ორივე ენაზე შეცვლი:

```js
address: {
  en: "Address: Apt 23B, 13 E. Ninoshvili St., Tbilisi, Georgia",
  ka: "მისამართი: ე. ნინოშვილის ქ. 13, ბ. 23B, თბილისი, საქართველო"
},
```

## სოციალური ქსელები

```js
social: {
  facebook:  "https://www.facebook.com/...",
  instagram: "https://www.instagram.com/...",
  tiktok:    ""
}
```

თუ ანგარიში ჯერ არ გაქვს — დატოვე ცარიელი ბრჭყალები (`""`) და **აიქონი საიტზე
საერთოდ არ გამოჩნდება**. მოგვიანებით ბმულს ჩასვამ და თავისით გამოჩნდება.

## რაზე მივაქციო ყურადღება

- ბრჭყალები `" "` და ხაზის ბოლოს მძიმე **არ წაშალო**
- მარცხნივ მდგარი სიტყვები (`phone`, `email`, `file`, `en`, `ka`) **არ გადაარქვა**
- შეცვლის შემდეგ ყოველთვის შეინახე ფაილი და გვერდი განაახლე (Ctrl+F5)
