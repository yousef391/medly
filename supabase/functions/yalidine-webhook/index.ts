import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { encode as hexEncode } from "https://deno.land/std@0.177.0/encoding/hex.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Yalidine webhook secret (for CRC validation)
const WEBHOOK_SECRET = "d347278370aba4e6d2dc615304151e26aa1e52b9f30f2d18ad3e01d0f656f26c";

async function hmacSha256(secret: string, message: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(message));
  return new TextDecoder().decode(hexEncode(new Uint8Array(signature)));
}

function mapStatus(status: string): string {
  const s = status.toLowerCase();
  if (["centre", "transfert", "exp\u00e9di\u00e9", "expedie"].some((k) => s.includes(k))) return "atWilaya";
  if (s.includes("sorti en livraison")) return "outForDelivery";
  if (s.includes("livr\u00e9") || s.includes("livre")) return "delivered";
  if (["retour", "retourn\u00e9", "retourne"].some((k) => s.includes(k))) return "returned";
  return "unknown";
}

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "*",
      },
    });
  }

  // Handle GET — Yalidine CRC token validation
  if (req.method === "GET") {
    const crcToken = url.searchParams.get("crc_token");
    if (crcToken) {
      // Yalidine does NOT use HMAC hashing for CRC like Twitter does.
      // It simply expects your server to echo back the exact same token in plain text.
      return new Response(crcToken, {
        status: 200,
        headers: { "Content-Type": "text/plain" },
      });
    }
    return new Response(JSON.stringify({ ok: true, message: "Webhook is active" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    // 1. EXTRACTION OF USER ID FROM URL 
    const userId = url.searchParams.get("user_id");

    if (!userId) {
      console.warn("Webhook rejected: Missing user_id in URL");
      return new Response(
        JSON.stringify({ error: "Missing user_id query parameter in webhook URL" }), 
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const payload = await req.json();
    const eventType = payload.type;
    const events = payload.events || [];

    console.log(`Received ${events.length} events of type: ${eventType} for User: ${userId}`);

    if (eventType !== "parcel_status_updated") {
      return new Response(
        JSON.stringify({ ok: true, skipped: true, reason: "Not a status update" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    const results = [];

    for (const event of events) {
      const { event_id, occurred_at, data } = event;
      const { tracking, status, reason } = data;

      // Check for duplicate (checking specifically for this user's duplicate)
      const { data: existing } = await supabase
        .from("sms_webhook_events")
        .select("id")
        .eq("event_id", event_id)
        .eq("user_id", userId)
        .maybeSingle();

      if (existing) {
        console.log(`Skipping duplicate event: ${event_id} for user ${userId}`);
        results.push({ event_id, skipped: true });
        continue;
      }

      // Look up customer from customers table FOR THIS SPECIFIC USER
      let customerName = null;
      let phoneNumber = null;
      let wilaya = null;
      let commune = null;
      let orderId = null;

      const { data: customer } = await supabase
        .from("customers")
        .select("*")
        .eq("tracking", tracking)
        .eq("user_id", userId) // <-- Important: don't accidentally fetch another seller's customer!
        .maybeSingle();

      if (customer) {
        customerName = customer.customer_name;
        phoneNumber = customer.phone_number;
        wilaya = customer.wilaya;
        commune = customer.commune;
        orderId = customer.order_id;
        console.log(`Found customer for ${tracking}: ${customerName} - ${phoneNumber}`);
      } else {
        console.warn(`No customer found for tracking: ${tracking} for user: ${userId}`);
      }

      const mappedEventType = mapStatus(status);

      // Insert event into sms_webhook_events ATTACHED TO THIS USER
      const { error: insertError } = await supabase
        .from("sms_webhook_events")
        .insert({
          user_id: userId, // <-- Added user_id here
          event_id,
          event_type: mappedEventType,
          tracking,
          status,
          reason,
          customer_name: customerName,
          phone_number: phoneNumber,
          wilaya,
          commune,
          order_id: orderId,
          raw_payload: event,
          processed: false,
          occurred_at: occurred_at ? new Date(occurred_at).toISOString() : null,
        });

      if (insertError) {
        console.error(`Failed to insert event ${event_id}:`, insertError);
        results.push({ event_id, error: insertError.message });
      } else {
        console.log(`Inserted event ${event_id} for tracking ${tracking}`);
        results.push({ event_id, success: true });
      }
    }

    return new Response(JSON.stringify({ ok: true, results }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Webhook error:", err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
