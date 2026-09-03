/* ============================================================
   Google Analytics 4 (gtag.js)
   ------------------------------------------------------------
   HOW TO TURN IT ON (do this once, after the site is hosted):
     1. Go to  https://analytics.google.com  and create a GA4
        property for your website (oritoki.ge).
     2. Copy the Measurement ID — it looks like  G-XXXXXXXXXX
     3. Paste it below on the GA_MEASUREMENT_ID line, replacing
        the placeholder. Save. That's it — both index.html and
        join.html use this one file.

   Until a real ID is set here, nothing loads and no data is
   collected. It also stays off while you preview the files
   locally (file://), so your own test visits aren't counted.
   ============================================================ */
(function () {
  var GA_MEASUREMENT_ID = "G-XXXXXXXXXX"; // ← replace with your GA4 Measurement ID

  // Not configured yet, or a local file preview → do nothing.
  if (!GA_MEASUREMENT_ID || GA_MEASUREMENT_ID === "G-XXXXXXXXXX") return;
  if (location.protocol === "file:") return;

  var s = document.createElement("script");
  s.async = true;
  s.src = "https://www.googletagmanager.com/gtag/js?id=" + GA_MEASUREMENT_ID;
  document.head.appendChild(s);

  window.dataLayer = window.dataLayer || [];
  window.gtag = function () { window.dataLayer.push(arguments); };
  gtag("js", new Date());
  gtag("config", GA_MEASUREMENT_ID);
})();
