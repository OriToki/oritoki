/* =====================================================================
   GET /en  —  the English home page
   ---------------------------------------------------------------------
   There is ONE page, index.html. oritoki.ge/ serves it as it is (Georgian);
   this Pages Function serves the same file at oritoki.ge/en as an English
   page, so search engines and AI crawlers — most of which never run our
   JavaScript — find each language at its own address:

     <html lang>            → "en"
     [data-en] elements     → their text becomes the data-en value
     [data-en-content]      → <meta content> becomes that value
     [data-en-href]         → <link href> becomes that value (the canonical)
     [data-en-alt]          → <img alt> becomes that value

   Nothing to maintain here when wording changes: edit index.html, both
   addresses follow. The page's own script then shows the language the
   address says (or the visitor's saved choice). hreflang links in
   index.html tie the two addresses together.
   ===================================================================== */

// lol-html hands attribute values over as written in the markup; undo the entities so they can be
// set as text or HTML. (&amp; last, so "&amp;lt;" stays "&lt;".)
const decode = (s) =>
  s.replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");

export async function onRequestGet({ request, env }) {
  const page = await env.ASSETS.fetch(new URL("/", request.url));
  if (!page.ok || !(page.headers.get("content-type") || "").includes("text/html")) return page;

  const res = new HTMLRewriter()
    .on("html", { element(e) { e.setAttribute("lang", "en"); } })
    .on("[data-en]", {
      element(e) {
        // data-en holds innerHTML (plain text with entities), so it goes in as HTML.
        e.setInnerContent(decode(e.getAttribute("data-en")), { html: true });
      },
    })
    .on("[data-en-content]", { element(e) { e.setAttribute("content", decode(e.getAttribute("data-en-content"))); } })
    .on("[data-en-href]", { element(e) { e.setAttribute("href", decode(e.getAttribute("data-en-href"))); } })
    .on("[data-en-alt]", { element(e) { e.setAttribute("alt", decode(e.getAttribute("data-en-alt"))); } })
    .transform(page);

  const headers = new Headers(res.headers);
  headers.set("content-language", "en");
  return new Response(res.body, { status: 200, headers });
}
