/* =====================================================================
   oritoki-mailer  —  a Cloudflare WORKER (not part of the Pages site)
   ---------------------------------------------------------------------
   Sends the e-mail that functions/api/apply.js builds from the Join form
   to the owner's mailbox. It exists only because Pages Functions cannot
   hold a send_email binding; the Pages project reaches it through a
   service binding called MAILER.

   It is deployed by hand, once, in the Cloudflare dashboard — a git push
   does NOT update it. Setup (oritoki.ge must be on Cloudflare first, with
   Email Routing on and the owner's mailbox verified as a destination):

     Variables (Settings → Variables):
       FROM = form@oritoki.ge          any address @oritoki.ge
       TO   = <the owner's verified mailbox>
     Binding:
       send_email, name EMAIL, destination_address = the same mailbox as TO
     Domains & Routes: turn workers.dev OFF — only the site may call this.

   The owner's address lives only in those settings, never in the repo.
   ===================================================================== */
import { EmailMessage } from "cloudflare:email";

export default {
  async fetch(request, env) {
    if (request.method !== "POST") return new Response("Method not allowed", { status: 405 });
    const body = await request.text();
    // apply.js sends a complete message minus From/To; those are ours to set.
    if (!/^Subject: /.test(body) || body.length > 5 * 1024 * 1024) return new Response("Bad message", { status: 400 });
    const raw = 'From: "ORITOKI website" <' + env.FROM + ">\r\nTo: <" + env.TO + ">\r\n" + body;
    try {
      await env.EMAIL.send(new EmailMessage(env.FROM, env.TO, raw));
    } catch (e) {
      return new Response("Send failed: " + e.message, { status: 502 });
    }
    return new Response("ok");
  },
};
