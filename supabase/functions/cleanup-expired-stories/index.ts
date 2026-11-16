// Removes expired Story media and rows. Invoke from Supabase Cron every 15 minutes.
const json = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });

function constantTimeEqual(a: string, b: string) {
  let diff = a.length ^ b.length;
  const length = Math.max(a.length, b.length);
  for (let i = 0; i < length; i++) {
    diff |= (a.charCodeAt(i % Math.max(1, a.length)) || 0) ^
      (b.charCodeAt(i % Math.max(1, b.length)) || 0);
  }
  return diff === 0;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const expected = Deno.env.get("CRON_SECRET") || "";
  const supplied = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!expected || !supplied || !constantTimeEqual(supplied, expected)) {
    return json({ error: "Unauthorized" }, 401);
  }

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) return json({ error: "Server environment is not configured" }, 500);

  const { createClient } = await import("https://esm.sh/@supabase/supabase-js@2");
  const admin = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    const cutoff = new Date().toISOString();
    const { data: expired, error: readError } = await admin
      .from("madal_stories")
      .select("id,storage_path")
      .lte("expires_at", cutoff)
      .order("expires_at", { ascending: true })
      .limit(500);
    if (readError) throw new Error(`Unable to read expired Stories: ${readError.message}`);
    if (!expired?.length) {
      const staleCutoff = new Date(Date.now() - 90000).toISOString();
      const { data: stale, error: staleError } = await admin.from("madal_live_sessions")
        .update({ status: "ended", ended_at: cutoff })
        .eq("status", "live").lt("last_heartbeat_at", staleCutoff).select("id");
      if (staleError) throw new Error(`Unable to end abandoned LIVE sessions: ${staleError.message}`);
      return json({ success: true, deleted: 0, endedLiveSessions: stale?.length || 0, remainingBatch: false });
    }

    const paths = expired.map((story) => story.storage_path).filter(Boolean);
    for (let i = 0; i < paths.length; i += 100) {
      const { error } = await admin.storage.from("madal-media").remove(paths.slice(i, i + 100));
      if (error) throw new Error(`Unable to remove expired Story media: ${error.message}`);
    }

    const ids = expired.map((story) => story.id);
    const { error: deleteError } = await admin.from("madal_stories").delete().in("id", ids);
    if (deleteError) throw new Error(`Unable to delete expired Story rows: ${deleteError.message}`);

    const staleCutoff = new Date(Date.now() - 90000).toISOString();
    const { data: stale, error: staleError } = await admin.from("madal_live_sessions")
      .update({ status: "ended", ended_at: cutoff })
      .eq("status", "live").lt("last_heartbeat_at", staleCutoff).select("id");
    if (staleError) throw new Error(`Unable to end abandoned LIVE sessions: ${staleError.message}`);

    return json({ success: true, deleted: ids.length, endedLiveSessions: stale?.length || 0, remainingBatch: ids.length === 500 });
  } catch (error) {
    console.error("GoGol expired Story cleanup failed:", error);
    return json({ error: error instanceof Error ? error.message : "Cleanup failed" }, 500);
  }
});
