import { createClient } from 'npm:@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { ...cors, 'Content-Type': 'application/json' },
});

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (request.method !== 'POST') return json({ error: 'POST required' }, 405);
  const token = request.headers.get('Authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) return json({ error: 'Sign in required' }, 401);
  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  try {
    const { data: { user }, error: authError } = await admin.auth.getUser(token);
    if (authError || !user) return json({ error: 'Invalid session' }, 401);
    const { data: principal, error: profileError } = await admin.from('profiles').select('role,is_active,school_id').eq('id', user.id).single();
    if (profileError || !principal?.is_active || principal.role !== 'principal') return json({ error: 'Principal access required' }, 403);
    const body = await request.json();
    const fullName = String(body.full_name ?? '').trim();
    const email = String(body.email ?? '').trim();
    const employee = String(body.employee_number ?? '').trim();
    const password = String(body.password ?? '');
    if (!fullName || !employee || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || password.length < 8) return json({ error: 'Name, employee number, valid email and an 8-character password are required.' }, 400);
    if (!Array.isArray(body.subjects) || body.subjects.some((s: unknown) => typeof s !== 'string')) return json({ error: 'Invalid subjects' }, 400);
    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email, password, email_confirm: true,
      user_metadata: { full_name: fullName, role: 'teacher' },
    });
    if (createError || !created.user) return json({ error: createError?.message ?? 'Could not create teacher' }, 400);
    const { error: recordError } = await admin.rpc('create_teacher_record', {
      user_id: created.user.id, sid: principal.school_id,
      teacher_values: { full_name: fullName, employee_number: employee, phone: String(body.phone ?? '').trim(), subjects: body.subjects },
    });
    if (recordError) {
      // Roll back the newly created auth account if school record creation fails.
      const { error: cleanupError } = await admin.auth.admin.deleteUser(created.user.id);
      if (cleanupError) console.error('Teacher account cleanup failed for', created.user.id);
      return json({ error: recordError.message }, 400);
    }
    return json({ id: created.user.id });
  } catch {
    return json({ error: 'Could not process teacher creation. Please try again.' }, 500);
  }
});
