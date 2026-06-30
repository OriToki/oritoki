/* =====================================================================
   ORITOKI — main script
   Handles: mobile menu, sticky header, language switch (EN/KA),
            building the photo carousel, scroll reveal + active link.
   You normally do NOT need to edit this file.
   ===================================================================== */
(function () {
  "use strict";

  /* ---------- 1. Build the gallery slides from js/images.js ---------- */
  var wrapper = document.getElementById("gallery-wrapper");
  if (wrapper && Array.isArray(window.galleryImages)) {
    window.galleryImages.forEach(function (img) {
      var slide = document.createElement("div");
      slide.className = "swiper-slide";
      slide.innerHTML =
        '<img src="images/gallery/' + img.file + '" alt="' + img.en + '" loading="lazy" />' +
        '<div class="slide-caption" data-ka="' + img.ka + '">' + img.en + "</div>";
      wrapper.appendChild(slide);
    });
  }

  /* ---------- 2. Start the Swiper carousel ---------- */
  if (window.Swiper && document.querySelector(".gallery-swiper")) {
    new Swiper(".gallery-swiper", {
      slidesPerView: 1,
      spaceBetween: 20,
      loop: window.galleryImages && window.galleryImages.length > 2,
      grabCursor: true,
      autoplay: { delay: 4000, disableOnInteraction: false },
      pagination: { el: ".swiper-pagination", clickable: true },
      navigation: { nextEl: ".swiper-button-next", prevEl: ".swiper-button-prev" },
      breakpoints: {
        640: { slidesPerView: 2 },
        1000: { slidesPerView: 3 },
      },
    });
  }

  /* ---------- 3. Language switch (English / Georgian) ---------- */
  var LANG_KEY = "oritoki_lang";
  var langToggle = document.getElementById("langToggle");
  var langLabel = document.getElementById("langLabel");

  function applyLanguage(lang) {
    document.documentElement.lang = lang;

    // text content
    document.querySelectorAll("[data-ka]").forEach(function (el) {
      if (el.dataset.en === undefined) el.dataset.en = el.innerHTML; // remember English once
      el.innerHTML = lang === "ka" ? el.dataset.ka : el.dataset.en;
    });

    // input / textarea placeholders
    document.querySelectorAll("[data-ka-placeholder]").forEach(function (el) {
      if (el.dataset.enPlaceholder === undefined) el.dataset.enPlaceholder = el.placeholder;
      el.placeholder = lang === "ka" ? el.dataset.kaPlaceholder : el.dataset.enPlaceholder;
    });

    // the toggle button shows the OTHER language you can switch to
    if (langLabel) langLabel.textContent = lang === "ka" ? "English" : "ქართული";

    try { localStorage.setItem(LANG_KEY, lang); } catch (e) {}
  }

  var savedLang = "en";
  try { savedLang = localStorage.getItem(LANG_KEY) || "en"; } catch (e) {}
  applyLanguage(savedLang);

  if (langToggle) {
    langToggle.addEventListener("click", function () {
      var next = document.documentElement.lang === "ka" ? "en" : "ka";
      applyLanguage(next);
    });
  }

  /* ---------- 4. Sticky header style on scroll ---------- */
  var header = document.getElementById("header");
  function onScroll() {
    if (window.scrollY > 40) header.classList.add("scrolled");
    else header.classList.remove("scrolled");
  }
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });

  /* ---------- 5. Mobile menu open / close ---------- */
  var burger = document.getElementById("burger");
  var nav = document.getElementById("nav");
  function closeMenu() {
    nav.classList.remove("open");
    burger.classList.remove("open");
    burger.setAttribute("aria-expanded", "false");
  }
  if (burger && nav) {
    burger.addEventListener("click", function () {
      var open = nav.classList.toggle("open");
      burger.classList.toggle("open", open);
      burger.setAttribute("aria-expanded", open ? "true" : "false");
    });
    nav.querySelectorAll(".nav-link").forEach(function (link) {
      link.addEventListener("click", closeMenu);
    });
  }

  /* ---------- 6. Highlight the active menu item while scrolling ---------- */
  var sections = document.querySelectorAll("section[id]");
  var navLinks = document.querySelectorAll(".nav-link");
  if ("IntersectionObserver" in window && sections.length) {
    var spy = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          var id = entry.target.getAttribute("id");
          navLinks.forEach(function (link) {
            link.classList.toggle("active", link.getAttribute("href") === "#" + id);
          });
        });
      },
      { rootMargin: "-45% 0px -50% 0px" }
    );
    sections.forEach(function (s) { spy.observe(s); });
  }

  /* ---------- 7. Reveal elements as they enter the screen ---------- */
  var reveals = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && reveals.length) {
    var revObserver = new IntersectionObserver(
      function (entries, obs) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("in");
            obs.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15 }
    );
    reveals.forEach(function (el) { revObserver.observe(el); });
  } else {
    reveals.forEach(function (el) { el.classList.add("in"); });
  }

  /* ---------- 8. Footer year ---------- */
  var yearEl = document.getElementById("year");
  if (yearEl) yearEl.textContent = new Date().getFullYear();
})();
