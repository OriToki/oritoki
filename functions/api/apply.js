/* =====================================================================
   POST /api/apply  —  the "Join our network" form on join.html
   ---------------------------------------------------------------------
   The owner wants every application in his MAILBOX and nowhere else:
   no database, no storage bucket, no third-party form service. So this
   Cloudflare Pages Function takes the form, turns it into one e-mail
   (every field + the certificate as an attachment) and hands it to the
   small `oritoki-mailer` Worker (worker/oritoki-mailer.js) through the
   service binding MAILER. That Worker adds From/To and sends it with
   Cloudflare's own send_email binding to his verified address. Nothing
   is written anywhere along the way.

   Pages Functions cannot hold a send_email binding themselves (only
   Workers can), which is the only reason the mailer is a separate Worker.

   Until MAILER is bound (Pages project → Settings → Bindings → Service
   binding, name MAILER → oritoki-mailer) this answers 503, and the form
   tells the visitor to call or WhatsApp instead.
   ===================================================================== */

// One message may be at most 5 MiB with its attachment, and base64 makes a file a third bigger.
// join.html shrinks photos before sending, so in practice only a large PDF ever meets this.
const MAX_FILE = 3.5 * 1024 * 1024;
const FILE_TYPES = { "application/pdf": "pdf", "image/jpeg": "jpg", "image/png": "png" };

const json = (status, body) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json; charset=utf-8" } });

export async function onRequestPost({ request, env }) {
  // Only our own page may post here (a browser always sends Origin on a POST).
  const origin = request.headers.get("origin");
  if (origin && new URL(origin).host !== new URL(request.url).host) return json(403, { ok: false, error: "origin" });

  let fd;
  try { fd = await request.formData(); } catch (e) { return json(400, { ok: false, error: "bad_form" }); }

  const get = (name, max = 200) => String(fd.get(name) || "").trim().slice(0, max);
  const all = (name) => fd.getAll(name).map((v) => String(v).trim().slice(0, 100)).filter(Boolean);

  // Honeypot: a field people never see. Bots fill it; pretend it went through and drop it.
  if (get("website")) return json(200, { ok: true });

  const f = {
    first: get("first_name", 80),
    last: get("last_name", 80),
    phone: (get("phone_code", 8) + " " + get("phone", 40)).trim(),
    email: get("email", 120),
    city: get("city", 80),
    country: get("country", 80),
    certs: withOther(all("certifications"), get("cert_other", 120)),
    level: get("rope_level", 40),
    langs: withOther(all("languages"), get("lang_other", 120)),
    ppe: get("own_ppe", 40),
    notes: get("notes", 4000),
  };
  if (!f.first || !f.last || !get("phone", 40)) return json(400, { ok: false, error: "required" });

  let file = null;
  const up = fd.get("certificate");
  if (up && typeof up === "object" && up.size > 0) {
    if (up.size > MAX_FILE) return json(413, { ok: false, error: "file_size" });
    const bytes = new Uint8Array(await up.arrayBuffer());
    const type = sniff(bytes);
    if (!type) return json(415, { ok: false, error: "file_type" });
    const base = (up.name || "certificate").replace(/\.[^.]*$/, "").replace(/[^\p{L}\p{N}._ -]/gu, "_").slice(0, 60) || "certificate";
    file = { name: base + "." + FILE_TYPES[type], type, bytes };
  }

  if (!env.MAILER) return json(503, { ok: false, error: "not_configured" });

  const name = f.first + " " + f.last;
  const rows = [
    ["სახელი, გვარი", name],
    ["ტელეფონი", f.phone],
    ["ელ. ფოსტა", f.email],
    ["ქალაქი", f.city],
    ["ქვეყანა", f.country],
    ["სერტიფიკატები", f.certs.join(", ")],
    ["Rope Access დონე", f.level],
    ["ენები", f.langs.join(", ")],
    ["საკუთარი PPE", f.ppe],
    ["დამატებითი ინფორმაცია", f.notes],
    ["ატვირთული ფაილი", file ? file.name + " (დანართად)" : ""],
    ["ენა საიტზე", get("lang", 5) === "en" ? "English" : "ქართული"],
  ];

  const text = rows.map(([k, v]) => k + ": " + (v || "—")).join("\n");
  const html =
    '<div style="font-family:Arial,sans-serif;font-size:15px;color:#111">' +
    '<h2 style="margin:0 0 14px;color:#f97316">ახალი განაცხადი — ' + esc(name) + "</h2>" +
    '<table cellpadding="7" style="border-collapse:collapse">' +
    rows.map(([k, v]) =>
      '<tr><td style="border-bottom:1px solid #eee;color:#666;vertical-align:top;white-space:nowrap">' + esc(k) +
      '</td><td style="border-bottom:1px solid #eee;white-space:pre-wrap">' + (v ? esc(v) : "—") + "</td></tr>").join("") +
    "</table></div>";

  const replyTo = /^[^\s@<>"]+@[^\s@<>"]+\.[^\s@<>"]+$/.test(f.email) ? f.email : "";
  const mime = buildMime({ subject: "ახალი განაცხადი — " + name, replyTo, text, html, file });

  try {
    const r = await env.MAILER.fetch("https://mailer/send", {
      method: "POST",
      headers: { "content-type": "message/rfc822" },
      body: mime,
    });
    if (!r.ok) return json(502, { ok: false, error: "send_failed" });
  } catch (e) {
    return json(502, { ok: false, error: "send_failed" });
  }
  return json(200, { ok: true });
}

function withOther(list, other) {
  const out = list.filter((v) => v !== "__other__");
  if (list.includes("__other__") && other) out.push(other);
  return out;
}

// Trust the file's first bytes, not its name or the type the browser claims.
function sniff(b) {
  if (b[0] === 0x25 && b[1] === 0x50 && b[2] === 0x44 && b[3] === 0x46) return "application/pdf";   // %PDF
  if (b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return "image/jpeg";
  if (b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47) return "image/png";
  return null;
}

function esc(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

/* ---------- MIME ----------
   Everything except From/To, which the mailer Worker puts on top — it alone knows the owner's
   address, so that address never appears in this public repository. */
function b64(bytes) {
  let s = "";
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
  return btoa(s);
}
const b64text = (str) => b64(new TextEncoder().encode(str));
const wrap = (s) => s.replace(/.{1,76}/g, "$&\r\n");
const word = (str) => "=?UTF-8?B?" + b64text(str) + "?=";   // RFC 2047, for Georgian in headers

function buildMime({ subject, replyTo, text, html, file }) {
  const id = crypto.randomUUID();
  const mixed = "mixed-" + id, alt = "alt-" + id;
  const L = [
    "Subject: " + word(subject),
    "Date: " + new Date().toUTCString(),
    "Message-ID: <" + id + "@oritoki.ge>",
  ];
  if (replyTo) L.push("Reply-To: <" + replyTo + ">");
  L.push(
    "MIME-Version: 1.0",
    'Content-Type: multipart/mixed; boundary="' + mixed + '"',
    "",
    "--" + mixed,
    'Content-Type: multipart/alternative; boundary="' + alt + '"',
    "",
    "--" + alt,
    "Content-Type: text/plain; charset=UTF-8",
    "Content-Transfer-Encoding: base64",
    "",
    wrap(b64text(text)),
    "--" + alt,
    "Content-Type: text/html; charset=UTF-8",
    "Content-Transfer-Encoding: base64",
    "",
    wrap(b64text(html)),
    "--" + alt + "--",
    "",
  );
  if (file) {
    L.push(
      "--" + mixed,
      "Content-Type: " + file.type + '; name="' + word(file.name) + '"',
      'Content-Disposition: attachment; filename="' + word(file.name) + '"',
      "Content-Transfer-Encoding: base64",
      "",
      wrap(b64(file.bytes)),
    );
  }
  L.push("--" + mixed + "--", "");
  return L.join("\r\n");
}
