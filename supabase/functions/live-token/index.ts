import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { AccessToken } from "npm:livekit-server-sdk@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function reply(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return reply({ error: "Method not allowed" }, 405);

  const authorization = req.headers.get("Authorization") || "";
  if (!authorization.startsWith("Bearer ")) return reply({ error: "Sign in is required" }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const livekitUrl = Deno.env.get("LIVEKIT_URL");
  const livekitKey = Deno.env.get("LIVEKIT_API_KEY");
  const livekitSecret = Deno.env.get("LIVEKIT_API_SECRET");
  if (!supabaseUrl || !anonKey || !serviceKey || !livekitUrl || !livekitKey || !livekitSecret) {
    return reply({ error: "LIVE adeeggiisa weli lama habayn. Maamulka ha dejiyo LiveKit secrets." }, 503);
  }

  const auth = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: authData, error: authError } = await auth.auth.getUser();
  if (authError || !authData.user) return reply({ error: "Session-kaagu ma shaqaynayo; dib u gal." }, 401);

  let body: { session_id?: string; role?: string };
  try { body = await req.json(); } catch { return reply({ error: "Codsi khaldan." }, 400); }
  if (!body.session_id || !/^[0-9a-f-]{36}$/i.test(body.session_id) || !["host", "viewer"].includes(body.role || "")) {
    return reply({ error: "LIVE session ama doorka waa khaldan yahay." }, 400);
  }

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: session, error } = await admin.from("madal_live_sessions")
    .select("id,host_id,room_name,title,status")
    .eq("id", body.session_id)
    .maybeSingle();
  if (error || !session) return reply({ error: "LIVE-kan lama helin." }, 404);
  if (session.status !== "live") return reply({ error: "LIVE-kan waa dhammaaday." }, 410);

  const isHost = session.host_id === authData.user.id;
  if (body.role === "host" && !isHost) return reply({ error: "Kaliya qofka bilaabay LIVE-ga ayaa baahin kara." }, 403);
  if (body.role === "viewer" && isHost) return reply({ error: "Martigeliyaha hore ayuu ugu jiraa LIVE-ga." }, 400);

  const token = new AccessToken(livekitKey, livekitSecret, {
    identity: authData.user.id,
    ttl: "2h",
  });
  token.addGrant({
    roomJoin: true,
    room: session.room_name,
    canPublish: body.role === "host",
    canSubscribe: true,
    canPublishData: false,
  });

  return reply({ token: await token.toJwt(), server_url: livekitUrl, title: session.title });
});
