// Sends the queued notifications in public.push_outbox to Apple (APNs). Called by the database right after it
// queues one, and every 5 minutes to retry (see migration 20261029000007_push.sql).
//
// Secrets (`supabase secrets set ...`): PUSH_FUNCTION_SECRET, the same value as the Vault secret
// push_function_secret; APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, and APNS_PRIVATE_KEY, the .p8 key's text.
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.

import { createClient } from "@supabase/supabase-js";

interface OutboxRow {
  id: number;
  recipient_id: string;
  title: string;
  body: string;
  request_id: string;
  opens: "request" | "chat";
  attempts: number;
}

interface DeviceRow {
  token: string;
  environment: "sandbox" | "production";
}

const maxAttempts = 5;
const env = (name: string) => Deno.env.get(name) ?? "";

/// What the app receives: the alert, and where tapping it should go (NotificationRoute in FavorlyFeatures).
export function apnsPayload(row: OutboxRow) {
  return {
    aps: { alert: { title: row.title, body: row.body }, sound: "default", "thread-id": row.request_id },
    request_id: row.request_id,
    opens: row.opens,
  };
}

function base64url(bytes: Uint8Array | string): string {
  const data = typeof bytes === "string" ? new TextEncoder().encode(bytes) : bytes;
  let binary = "";
  for (const byte of data) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

let cachedToken: { jwt: string; issuedAt: number } | undefined;

/// The provider token APNs expects: an ES256 JWT, reused for 50 minutes (Apple allows up to 60).
async function providerToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && now - cachedToken.issuedAt < 50 * 60) return cachedToken.jwt;

  const pem = env("APNS_PRIVATE_KEY").replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey("pkcs8", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const header = base64url(JSON.stringify({ alg: "ES256", kid: env("APNS_KEY_ID") }));
  const claims = base64url(JSON.stringify({ iss: env("APNS_TEAM_ID"), iat: now }));
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  const jwt = `${header}.${claims}.${base64url(new Uint8Array(signature))}`;
  cachedToken = { jwt, issuedAt: now };
  return jwt;
}

/// Sends one notification to one device. Returns "sent", "gone" (the token is dead) or "failed".
async function send(device: DeviceRow, row: OutboxRow): Promise<"sent" | "gone" | "failed"> {
  const host = device.environment === "production" ? "api.push.apple.com" : "api.sandbox.push.apple.com";
  const response = await fetch(`https://${host}/3/device/${device.token}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${await providerToken()}`,
      "apns-topic": env("APNS_BUNDLE_ID"),
      "apns-push-type": "alert",
      "apns-priority": "10",
      "content-type": "application/json",
    },
    body: JSON.stringify(apnsPayload(row)),
  });
  if (response.ok) return "sent";
  const reason = (await response.json().catch(() => ({}))).reason ?? "";
  console.error(`APNs ${response.status} ${reason} for outbox ${row.id}`);
  return response.status === 410 || reason === "BadDeviceToken" ? "gone" : "failed";
}

Deno.serve(async (request) => {
  const secret = env("PUSH_FUNCTION_SECRET");
  if (!secret || request.headers.get("x-push-secret") !== secret) {
    return new Response("Forbidden", { status: 403 });
  }
  if (!env("APNS_KEY_ID") || !env("APNS_TEAM_ID") || !env("APNS_BUNDLE_ID") || !env("APNS_PRIVATE_KEY")) {
    return Response.json({ error: "APNs secrets are not set" }, { status: 503 });
  }

  const admin = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"));
  const { data: rows, error } = await admin
    .from("push_outbox")
    .select("id, recipient_id, title, body, request_id, opens, attempts")
    .is("sent_at", null)
    .lt("attempts", maxAttempts)
    .order("id")
    .limit(100);
  if (error) return Response.json({ error: error.message }, { status: 500 });

  let sent = 0;
  for (const row of (rows ?? []) as OutboxRow[]) {
    const { data: devices } = await admin
      .from("device_tokens")
      .select("token, environment")
      .eq("user_id", row.recipient_id);
    let delivered = (devices ?? []).length === 0; // Nobody to tell: done.
    for (const device of (devices ?? []) as DeviceRow[]) {
      const result = await send(device, row);
      if (result === "sent") delivered = true;
      if (result === "gone") await admin.from("device_tokens").delete().eq("token", device.token);
    }
    if (delivered) {
      await admin.from("push_outbox").update({ sent_at: new Date().toISOString() }).eq("id", row.id);
      sent += 1;
    } else {
      await admin.from("push_outbox").update({ attempts: row.attempts + 1 }).eq("id", row.id);
    }
  }
  return Response.json({ processed: rows?.length ?? 0, sent });
});
