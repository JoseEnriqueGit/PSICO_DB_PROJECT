import { createClient } from 'jsr:@supabase/supabase-js@2';
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS'
};
// Nuevos DATA_TYPES para la carga en cascada
const DATA_TYPES = {
  COUNTRIES: 'countries',
  PROVINCES: 'provinces',
  MUNICIPALITIES: 'municipalities',
  MUNICIPAL_DISTRICTS: 'municipal_districts',
  LOCAL_UNITS: 'local_units'
};
// Tipos de unidad administrativa tal como están en tu columna unit_type
const ADMIN_UNIT_TYPES = {
  COUNTRY: 'COUNTRY',
  PROVINCE: 'PROVINCE',
  MUNICIPALITY: 'MUNICIPALITY',
  MUNICIPAL_DISTRICT: 'MUNICIPAL_DISTRICT',
  SECTION: 'SECTION',
  NEIGHBORHOOD: 'NEIGHBORHOOD'
};
const UNIT_TYPE_TRANSLATIONS_ES = {
  [ADMIN_UNIT_TYPES.SECTION]: 'Sección',
  [ADMIN_UNIT_TYPES.NEIGHBORHOOD]: 'Barrio'
};
/* --- Variables de entorno ------------------------------------------------- */ const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
/* --- Helper para respuestas JSON ------------------------------------------- */ function jsonResponse(body, status = 200, additionalHeaders = {}) {
  return new Response(JSON.stringify(body), {
    headers: {
      ...CORS_HEADERS,
      'Content-Type': 'application/json; charset=utf-8',
      ...additionalHeaders
    },
    status
  });
}
/* --- Lógica de obtención de datos -------------------------------------------- */ // ✅ FUNCIÓN MEJORADA - getCountries con traducciones
async function getCountries(supabase, language) {
  if (!/^[a-z]{2}$/.test(language)) {
    return {
      data: null,
      error: {
        message: 'Invalid "lang" format.'
      },
      status: 400
    };
  }
  try {
    // Intentar obtener países con traducciones
    const { data, error } = await supabase.from('countries').select(`
        id,
        code,
        country_translations(
          translated_name
        )
      `).eq('is_deleted', false).eq('country_translations.language_code', language).order('code', {
      ascending: true
    });
    if (!error && data && data.length > 0) {
      // Si encontramos traducciones, usarlas
      const formattedData = data.map((country)=>({
          id: country.id,
          display_name: country.country_translations?.[0]?.translated_name || country.code
        }));
      return {
        data: formattedData,
        error: null,
        status: 200
      };
    }
    // Fallback: Si no hay traducciones o hay error, usar LEFT JOIN manual
    const { data: fallbackData, error: fallbackError } = await supabase.from('countries').select(`
        id,
        code,
        country_translations!left(
          translated_name
        )
      `).eq('is_deleted', false).or(`country_translations.language_code.eq.${language},country_translations.language_code.is.null`).order('code', {
      ascending: true
    });
    if (!fallbackError && fallbackData) {
      const formattedData = fallbackData.map((country)=>{
        // Buscar traducción para el idioma específico
        const translation = country.country_translations?.find((t)=>t.translated_name);
        return {
          id: country.id,
          display_name: translation?.translated_name || country.code
        };
      });
      return {
        data: formattedData,
        error: null,
        status: 200
      };
    }
    // Último fallback: solo códigos
    const { data: simpleData, error: simpleError } = await supabase.from('countries').select('id, code').eq('is_deleted', false).order('code', {
      ascending: true
    });
    if (simpleError) {
      console.error('Error fetching countries:', simpleError);
      return {
        data: null,
        error: {
          message: simpleError.message || "Failed to fetch countries."
        },
        status: 500
      };
    }
    const formattedData = simpleData ? simpleData.map((country)=>({
        id: country.id,
        display_name: country.code
      })) : [];
    return {
      data: formattedData,
      error: null,
      status: 200
    };
  } catch (err) {
    console.error('Error in getCountries:', err);
    return {
      data: null,
      error: {
        message: "Failed to fetch countries."
      },
      status: 500
    };
  }
}
async function getProvincesByCountry(supabase, countryId) {
  const { data, error } = await supabase.from('administrative_units').select('id, name') // Directamente name, ya que será display_name
  .eq('country_id', countryId).eq('unit_type', ADMIN_UNIT_TYPES.PROVINCE).order('name', {
    ascending: true
  });
  if (error) {
    console.error(`Error fetching provinces for countryId ${countryId}:`, error);
    return {
      data: null,
      error: {
        message: error.message || "Failed to fetch provinces."
      },
      status: 500
    };
  }
  // Formatear para que la salida sea { id, display_name }
  const formattedData = data ? data.map((p)=>({
      id: p.id,
      display_name: p.name
    })) : [];
  return {
    data: formattedData,
    error: null,
    status: 200
  };
}
async function getChildrenAdminUnits(supabase, parentId, childUnitTypes, formatDisplayNameForLocalUnits = false) {
  const { data, error } = await supabase.rpc('get_direct_admin_children', {
    p_parent_id: parentId,
    p_child_unit_types: childUnitTypes
  });
  if (error) {
    console.error(`Error fetching children for parentId ${parentId} with types ${childUnitTypes.join(', ')}:`, error);
    return {
      data: null,
      error: {
        message: error.message || "Failed to fetch children units."
      },
      status: 500
    };
  }
  let responseData = data || [];
  // Formatear display_name si es para LOCAL_UNITS
  if (formatDisplayNameForLocalUnits) {
    responseData = responseData.map((item)=>{
      const translatedUnitType = UNIT_TYPE_TRANSLATIONS_ES[item.unit_type] || item.unit_type;
      return {
        id: item.id,
        display_name: `${translatedUnitType} - ${item.name}`
      };
    });
  } else {
    // Para otros niveles, solo id y display_name (que es 'name')
    responseData = responseData.map((item)=>({
        id: item.id,
        display_name: item.name
      }));
  }
  return {
    data: responseData,
    error: null,
    status: 200
  };
}
/* --- Servidor Principal --------------------------------------------------- */ Deno.serve(async (req)=>{
  if (req.method === 'OPTIONS') return new Response('ok', {
    headers: CORS_HEADERS
  });
  if (req.method !== 'GET') return jsonResponse({
    error: 'Method Not Allowed'
  }, 405);
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.error('Server config error: Missing Supabase credentials.');
    return jsonResponse({
      error: 'Server configuration error'
    }, 500);
  }
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
      }
    }
  });
  try {
    const url = new URL(req.url);
    const params = {
      dataType: url.searchParams.get('type'),
      language: url.searchParams.get('lang'),
      countryId: url.searchParams.get('countryId'),
      parentId: url.searchParams.get('parentId')
    };
    // Normalizar params
    [
      'language',
      'countryId',
      'parentId'
    ].forEach((key)=>{
      const k = key;
      if (params[k] === 'null' || params[k] === '') params[k] = null;
    });
    if (!params.dataType) return jsonResponse({
      error: '"type" parameter is required'
    }, 400);
    let result;
    switch(params.dataType){
      case DATA_TYPES.COUNTRIES:
        if (!params.language) return jsonResponse({
          error: '"lang" is required for countries'
        }, 400);
        result = await getCountries(supabase, params.language);
        break;
      case DATA_TYPES.PROVINCES:
        if (!params.countryId) return jsonResponse({
          error: '"countryId" is required for provinces'
        }, 400);
        result = await getProvincesByCountry(supabase, params.countryId);
        break;
      case DATA_TYPES.MUNICIPALITIES:
        if (!params.parentId) return jsonResponse({
          error: '"parentId" (provinceId) is required for municipalities'
        }, 400);
        result = await getChildrenAdminUnits(supabase, params.parentId, [
          ADMIN_UNIT_TYPES.MUNICIPALITY
        ]);
        break;
      case DATA_TYPES.MUNICIPAL_DISTRICTS:
        if (!params.parentId) return jsonResponse({
          error: '"parentId" (municipalityId) is required for municipal districts'
        }, 400);
        result = await getChildrenAdminUnits(supabase, params.parentId, [
          ADMIN_UNIT_TYPES.MUNICIPAL_DISTRICT
        ]);
        break;
      case DATA_TYPES.LOCAL_UNITS:
        if (!params.parentId) return jsonResponse({
          error: '"parentId" (municipalityId or districtId) is required for local units'
        }, 400);
        result = await getChildrenAdminUnits(supabase, params.parentId, [
          ADMIN_UNIT_TYPES.SECTION,
          ADMIN_UNIT_TYPES.NEIGHBORHOOD
        ], true);
        break;
      default:
        return jsonResponse({
          error: 'Invalid "type" specified'
        }, 400);
    }
    if (result.error) return jsonResponse({
      error: result.error.message || 'An unexpected error occurred'
    }, result.status);
    return jsonResponse(result.data, result.status);
  } catch (err) {
    console.error('Unhandled Edge Function error:', err);
    const errorMessage = err instanceof Error && err.message ? err.message : 'Internal server error';
    return jsonResponse({
      error: errorMessage
    }, 500);
  }
});