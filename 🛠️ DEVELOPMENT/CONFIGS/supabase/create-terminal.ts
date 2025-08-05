import { createClient } from 'jsr:@supabase/supabase-js@2';
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
};
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
Deno.serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: CORS_HEADERS
    });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({
      error: 'Method not allowed'
    }), {
      headers: {
        ...CORS_HEADERS,
        'Content-Type': 'application/json'
      },
      status: 405
    });
  }
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    global: {
      headers: {
        Authorization: req.headers.get('Authorization') ?? ''
      }
    }
  });
  try {
    const body = await req.json();
    const { admin_user_id, terminal_name, street_address, postal_code, administrative_unit_id, subscription_plan_id } = body;
    if (!admin_user_id || !terminal_name || !administrative_unit_id) {
      return new Response(JSON.stringify({
        error: 'admin_user_id, terminal_name, and administrative_unit_id are required'
      }), {
        headers: {
          ...CORS_HEADERS,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    const { data, error } = await supabase.rpc('admin_create_terminal_onboarding', {
      p_admin_user_id: admin_user_id,
      p_terminal_name: terminal_name,
      p_administrative_unit_id: administrative_unit_id,
      p_street_address: street_address || null,
      p_postal_code: postal_code || null,
      p_subscription_plan_id: subscription_plan_id || null
    });
    if (error) {
      return new Response(JSON.stringify({
        error: error.message
      }), {
        headers: {
          ...CORS_HEADERS,
          'Content-Type': 'application/json'
        },
        status: 500
      });
    }
    return new Response(JSON.stringify({
      success: true,
      terminal_id: data,
      message: 'Terminal created successfully'
    }), {
      headers: {
        ...CORS_HEADERS,
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Internal server error'
    }), {
      headers: {
        ...CORS_HEADERS,
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
});