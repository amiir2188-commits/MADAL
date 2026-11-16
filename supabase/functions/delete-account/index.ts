import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function response(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function collectFiles(admin: ReturnType<typeof createClient>, bucket: string, userId: string) {
  const paths: string[] = [];
  async function walk(prefix: string) {
    let offset = 0;
    while (true) {
      const { data, error } = await admin.storage.from(bucket).list(prefix, { limit: 1000, offset });
      if (error) throw new Error(`Unable to list ${bucket}: ${error.message}`);
      const folders: string[] = [];
      for (const item of data || []) {
        if (item.id || item.metadata) paths.push(`${prefix}/${item.name}`);
        else folders.push(`${prefix}/${item.name}`);
      }
      for (const folder of folders) await walk(folder);
      if (!data || data.length < 1000) break;
      offset += 1000;
    }
  }
  await walk(userId);
  return paths;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return response({ error: "Method not allowed" }, 405);

  const authorization = req.headers.get("Authorization") || "";
  if (!authorization.startsWith("Bearer ")) return response({ error: "Authentication required" }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return response({ error: "Server environment is not configured" }, 500);
  }

  const authClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: authData, error: authError } = await authClient.auth.getUser();
  if (authError || !authData.user) return response({ error: "Invalid or expired session" }, 401);

  const userId = authData.user.id;
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let requestId: string | null = null;
  try {
    const { data: existing, error: requestReadError } = await admin
      .from("madal_account_deletion_requests")
      .select("id")
      .eq("user_id", userId)
      .in("status", ["pending", "in_review"])
      .order("requested_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (requestReadError) throw new Error(`Account deletion migration is not installed: ${requestReadError.message}`);

    if (existing?.id) {
      requestId = existing.id;
      const { error } = await admin.from("madal_account_deletion_requests")
        .update({ status: "in_review" }).eq("id", requestId);
      if (error) throw new Error(`Unable to update deletion request: ${error.message}`);
    } else {
      const { data, error } = await admin.from("madal_account_deletion_requests")
        .insert({ user_id: userId, status: "in_review" }).select("id").single();
      if (error) throw new Error(`Unable to create deletion request: ${error.message}`);
      requestId = data.id;
    }

    for (const bucket of ["madal-media", "madal-avatars"]) {
      const paths = await collectFiles(admin, bucket, userId);
      for (let i = 0; i < paths.length; i += 100) {
        const { error } = await admin.storage.from(bucket).remove(paths.slice(i, i + 100));
        if (error) throw new Error(`Unable to remove files from ${bucket}: ${error.message}`);
      }
    }

    const { error: deleteError } = await admin.auth.admin.deleteUser(userId, false);
    if (deleteError) throw new Error(`Unable to delete authentication account: ${deleteError.message}`);

    if (requestId) {
      const { error } = await admin.from("madal_account_deletion_requests")
        .delete().eq("id", requestId);
      if (error) console.error("GoGol deletion request cleanup:", error.message);
    }

    return response({ success: true });
  } catch (error) {
    if (requestId) {
      await admin.from("madal_account_deletion_requests")
        .update({ status: "pending" }).eq("id", requestId);
    }
    console.error("GoGol account deletion failed:", error);
    return response({ error: error instanceof Error ? error.message : "Account deletion failed" }, 500);
  }
});
