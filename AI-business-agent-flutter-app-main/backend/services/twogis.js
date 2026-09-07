import axios from 'axios';

const CATALOG_URL = 'https://catalog.api.2gis.com';

const BUSINESS_QUERIES = [
  { match: ['kafe', 'cafe', 'кафе'], query: 'кафе' },
  { match: ['restoran', 'restaurant', 'ресторан'], query: 'ресторан' },
  { match: ['ictimai iaşə', 'iaşə', 'restaurant', 'kafe', 'cafe', 'общепит', 'ресторан', 'кафейн'], query: 'кафе ресторан' },
  { match: ['məhsul', 'pərakəndə', 'market', 'supermarket', 'магазин', 'продукт'], query: 'магазин супермаркет' },
  { match: ['gözəllik', 'beauty', 'красот', 'салон'], query: 'салон красоты' },
  { match: ['təbabət', 'medical', 'klinika', 'aptek', 'аптек', 'дәріхан', 'медицин'], query: 'аптека клиника' },
  { match: ['avtoservis', 'auto', 'car', 'автосервис'], query: 'автосервис' },
  { match: ['qonaq evi', 'mehmanxana', 'hotel', 'гостиниц', 'отел'], query: 'гостиница отель' },
  { match: ['fitnes', 'fitness', 'sport', 'фитнес', 'спорт'], query: 'фитнес спортивный клуб' },
  { match: ['zoopark', 'baytarlıq', 'zoo', 'ветеринар', 'зоомагазин'], query: 'зоомагазин ветеринарная клиника' },
  { match: ['laborator', 'лаборатор'], query: 'медицинская лаборатория' },
  { match: ['stomat', 'dent', 'стомат'], query: 'стоматология' },
  { match: ['çatdırılma', 'pickup', 'пункт выдачи', 'выдачи'], query: 'пункт выдачи' },
  { match: ['elektronika', 'electronics', 'электроник'], query: 'магазин электроники' },
  { match: ['təmir', 'repair', 'ремонт', 'мастер'], query: 'ремонт мастерская' },
  { match: ['gül', 'flowers', 'цвет', 'сувенир'], query: 'цветы сувениры' },
  { match: ['tikinti', 'construction', 'стройматериал', 'хозтовар'], query: 'стройматериалы хозтовары' },
  { match: ['rabitə', 'telecom', 'оптик', 'связь'], query: 'салон связи оптика' },
  { match: ['təhsil', 'education', 'обучение', 'образован'], query: 'образование' },
  { match: ['logistika', 'logistics', 'логист'], query: 'логистика' },
  { match: ['xidmət', 'service', 'услуг'], query: 'услуги' },
];

function normalizeBusinessQuery(value = '') {
  const normalized = value.toLowerCase();
  const match = BUSINESS_QUERIES.find((item) =>
    item.match.some((term) => normalized.includes(term)),
  );
  return match?.query || value.split('—')[0].trim() || 'business';
}

function pointOf(item) {
  const point = item?.point || item?.geometry?.centroid;
  if (!point) return null;
  const lat = Number(point.lat);
  const lon = Number(point.lon);
  return Number.isFinite(lat) && Number.isFinite(lon) ? { lat, lon } : null;
}

function distanceMeters(from, to) {
  const earthRadius = 6371000;
  const lat1 = (from.lat * Math.PI) / 180;
  const lat2 = (to.lat * Math.PI) / 180;
  const dLat = ((to.lat - from.lat) * Math.PI) / 180;
  const dLon = ((to.lon - from.lon) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return Math.round(earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

function itemsFrom(response) {
  return response.data?.result?.items || response.data?.result?.data || [];
}

async function catalogGet(path, params, key) {
  const response = await axios.get(`${CATALOG_URL}${path}`, {
    params: { ...params, key },
    timeout: 12000,
  });
  const code = response.data?.meta?.code;
  if (code && code !== 200) {
    const message =
      response.data?.meta?.error_message ||
      response.data?.meta?.error?.message ||
      `2GIS API error ${code}`;
    const error = new Error(message);
    error.code = code;
    throw error;
  }
  return response;
}

async function geocode(address, city, key) {
  // Resolve the city-qualified address first. Searching a street or district
  // without its city can return a same-named place in another region.
  const queries = [...new Set([
    city && address && city !== address ? `${city}, ${address}` : null,
    address,
    address ? `${address}, Kazakhstan` : null,
    city ? `${city}, Kazakhstan` : null,
  ].filter(Boolean))];
  let lastError;

  for (const query of queries) {
    try {
      const response = await catalogGet(
        '/3.0/items/geocode',
        {
          q: query,
          fields: 'items.point,items.geometry.centroid,items.address,items.adm_div',
          page_size: 5,
        },
        key,
      );
      const item = itemsFrom(response).find((candidate) => pointOf(candidate));
      if (item) {
        return {
          source: '2GIS Catalog API',
          item,
          point: pointOf(item),
          address: item.full_name || item.address_name || query,
        };
      }
    } catch (error) {
      lastError = error;
      if (error.code && error.code !== 404) throw error;
    }
  }

  // 2GIS returns meta.code=404 for valid but unrecognised free-form input.
  // Use OSM only to obtain coordinates, then keep all nearby analysis live from
  // 2GIS. This prevents one bad address string from breaking the full report.
  try {
    const response = await axios.get('https://nominatim.openstreetmap.org/search', {
      params: { q: queries[0] || city, format: 'jsonv2', limit: 1 },
      headers: { 'User-Agent': 'AI-Business-Agent/1.0 location fallback' },
      timeout: 10000,
    });
    const result = response.data?.[0];
    if (result) {
      return {
        source: 'OpenStreetMap fallback + 2GIS Catalog API',
        item: null,
        point: { lat: Number(result.lat), lon: Number(result.lon) },
        address: result.display_name || queries[0] || city,
      };
    }
  } catch (error) {
    console.warn('Fallback geocoder failed:', error.message);
  }

  throw lastError || new Error('2GIS ünvanı xəritədə tapa bilmədi');
}

async function nearby(key, point, query, type = 'branch', fields) {
  try {
    const response = await catalogGet(
      '/3.0/items',
      {
        q: query,
        type,
        point: `${point.lon},${point.lat}`,
        location: `${point.lon},${point.lat}`,
        radius: 1000,
        sort: 'distance',
        // Demo 2GIS keys allow a maximum of 10 items per request.
        page_size: 10,
        fields: fields || 'items.point,items.address,items.rubrics,items.reviews,items.schedule,items.links,items.flags',
      },
      key,
    );
    return itemsFrom(response);
  } catch (error) {
    // A missing category/permission must not make the whole audit unusable.
    console.warn(`2GIS nearby search failed for ${query}:`, error.message);
    return [];
  }
}

async function detailsById(key, item) {
  if (!item?.id) return item;
  try {
    const response = await catalogGet('/3.0/items/byid', {
      id: item.id.toString(),
      fields: 'items.point,items.address,items.rubrics,items.reviews,items.schedule,items.schedule_special,items.flags,items.links,items.description,items.contact_groups',
    }, key);
    const detailed = itemsFrom(response)[0];
    return detailed ? { ...item, ...detailed } : item;
  } catch (error) {
    // Detail fields can require extra 2GIS permissions; keep the base result.
    console.warn(`2GIS details failed for ${item.id}:`, error.message);
    return item;
  }
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

async function analyzeGoogleLocation({ address, city, businessType }) {
  const key = process.env.GOOGLE_MAPS_API_KEY;
  if (!key) throw new Error('GOOGLE_MAPS_API_KEY konfiqurasiya edilməyib');
  const query = `${businessType} near ${address || city}`;
  const search = await axios.get('https://maps.googleapis.com/maps/api/place/textsearch/json', {
    params: { query, key, language: 'az' },
    timeout: 12000,
  });
  if (search.data?.status !== 'OK' && search.data?.status !== 'ZERO_RESULTS') {
    throw new Error(`Google Places API: ${search.data?.status || 'unknown error'}`);
  }
  const results = search.data?.results || [];
  const competitors = results.map((item) => ({
    id: item.place_id || null,
    name: item.name || 'Google obyekt',
    address: item.formatted_address || '',
    point: { lat: item.geometry?.location?.lat, lon: item.geometry?.location?.lng },
    distance_meters: null,
    rating: item.rating ?? null,
    review_count: item.user_ratings_total ?? 0,
    rubrics: item.types || [],
    schedule: item.opening_hours || null,
    business_status: item.business_status || null,
    price_level: item.price_level ?? null,
    website: item.website || null,
    phone: item.international_phone_number || item.formatted_phone_number || null,
    google_maps_url: item.url || null,
    editorial_summary: item.editorial_summary?.overview || null,
    address_components: item.address_components || [],
    comments: [],
  })).filter((item) => Number.isFinite(item.point.lat) && Number.isFinite(item.point.lon));
  await Promise.all(competitors.slice(0, 20).map(async (item) => {
    if (!item.id) return;
    try {
      const details = await axios.get('https://maps.googleapis.com/maps/api/place/details/json', {
        params: {
          place_id: item.id,
          fields: 'opening_hours,reviews,user_ratings_total,rating,formatted_address,name,geometry,business_status,price_level,types,url,website,international_phone_number,formatted_phone_number,address_components,editorial_summary',
          key,
          language: 'az',
        },
        timeout: 12000,
      });
      const result = details.data?.result;
      if (!result) return;
      item.schedule = result.opening_hours || item.schedule;
      item.rating = result.rating ?? item.rating;
      item.review_count = result.user_ratings_total ?? item.review_count;
      item.business_status = result.business_status || item.business_status;
      item.price_level = result.price_level ?? item.price_level;
      item.website = result.website || item.website;
      item.phone = result.international_phone_number || result.formatted_phone_number || item.phone;
      item.google_maps_url = result.url || item.google_maps_url;
      item.editorial_summary = result.editorial_summary?.overview || item.editorial_summary;
      item.address_components = result.address_components || item.address_components;
      item.comments = (result.reviews || []).slice(0, 3).map((review) => ({
        text: review.text || null,
        rating: review.rating ?? null,
        author: review.author_name || null,
      })).filter((review) => review.text);
    } catch (error) {
      console.warn(`Google place details failed for ${item.id}:`, error.message);
    }
  }));
  const point = competitors[0]?.point || null;
  return {
    success: true,
    source: 'Google Places API',
    updated_at: new Date().toISOString(),
    address: competitors[0]?.address || address || city,
    point,
    score: 0,
    pedestrian_traffic: null,
    pedestrian_traffic_estimate: null,
    competitors_500m: competitors.length,
    competitors_1km: competitors.length,
    nearest_competitor_meters: null,
    accessibility_score: null,
    competition_score: null,
    business_query: businessType,
    competitors,
    transport_stops_1km: 0,
    transport_stops: [],
    parking_1km: 0,
    parking: [],
    nearby_places: [],
    nearby_places_1km: 0,
    insights: {
      digital_noise: { review_total: competitors.reduce((sum, item) => sum + item.review_count, 0), leaders: competitors.slice(0, 4) },
      peak_comparison: { schedule_available_for: competitors.filter((item) => item.schedule).length, competitors_sample: competitors.length },
    },
  };
}

export async function analyze2GisLocation({ address, city, businessType, provider }) {
  if ((provider || process.env.MAPS_PROVIDER || '2gis').toLowerCase() === 'google') {
    return analyzeGoogleLocation({ address, city, businessType });
  }
  const key = process.env.TWOGIS_API_KEY;
  if (!key) throw new Error('TWOGIS_API_KEY konfiqurasiya edilməyib');

  const geocoded = await geocode(address || city, city, key);
  const point = geocoded.point;
  const businessQuery = normalizeBusinessQuery(businessType);

  const [competitorItems, transportItems, parkingItems, publicPlaceItems] = await Promise.all([
    nearby(key, point, businessQuery),
    nearby(key, point, 'остановка общественного транспорта', 'station'),
    nearby(key, point, 'парковка', 'parking', 'items.point,items.address,items.is_paid,items.capacity,items.level_count,items.access,items.paving_type,items.links,items.reviews,items.schedule'),
    nearby(key, point, 'магазин кафе аптека', 'branch'),
  ]);

  const detailedCompetitorItems = await Promise.all(
    competitorItems.slice(0, 20).map((item) => detailsById(key, item)),
  );
  const detailedTransportItems = await Promise.all(
    transportItems.slice(0, 20).map((item) => detailsById(key, item)),
  );
  const detailedParkingItems = await Promise.all(
    parkingItems.slice(0, 20).map((item) => detailsById(key, item)),
  );

  const competitors = detailedCompetitorItems
    .map((item) => {
      const itemPoint = pointOf(item);
      if (!itemPoint) return null;
      return {
        id: item.id?.toString() || null,
        name: item.name || item.full_name || '2GIS obyekt',
        address: item.address_name || item.full_name || '',
        point: itemPoint,
        distance_meters: distanceMeters(point, itemPoint),
        rating: item.reviews?.general_rating ?? item.reviews?.rating ?? item.reviews?.org_rating ?? null,
        review_count: item.reviews?.general_review_count ?? item.reviews?.review_count ?? item.reviews?.org_review_count ?? 0,
        rubrics: (Array.isArray(item.rubrics) ? item.rubrics : []).map((rubric) => rubric.name).filter(Boolean),
        schedule: item.schedule || null,
        schedule_special: item.schedule_special || null,
        description: item.description || null,
        links: item.links || null,
        contact_groups: item.contact_groups || null,
        flags: item.flags || [],
      };
    })
    .filter(Boolean)
    .sort((a, b) => a.distance_meters - b.distance_meters);

  const competitors500m = competitors.filter((item) => item.distance_meters <= 500);
  const nearest = competitors[0]?.distance_meters ?? null;
  const reviewLeaders = [...competitors]
    .filter((item) => Number(item.review_count) > 0)
    .sort((a, b) => Number(b.review_count) - Number(a.review_count));
  const reviewTotal = reviewLeaders.reduce(
    (sum, item) => sum + Number(item.review_count || 0),
    0,
  );
  const scheduleAvailable = competitors.filter((item) => item.schedule).length;
  const totalNearby = publicPlaceItems.length;
  const transportCount = transportItems.length;
  const parking = detailedParkingItems
    .map((item) => {
      const itemPoint = pointOf(item);
      if (!itemPoint) return null;
      return {
        id: item.id?.toString() || null,
        name: item.name || item.full_name || 'Parking',
        address: item.address_name || item.full_name || '',
        point: itemPoint,
        distance_meters: distanceMeters(point, itemPoint),
        is_paid: item.is_paid ?? null,
        capacity: item.capacity ?? null,
        level_count: item.level_count ?? null,
        access: item.access ?? null,
        paving_type: item.paving_type ?? null,
        schedule: item.schedule || null,
        review_count: item.reviews?.general_review_count ?? item.reviews?.review_count ?? 0,
        comments: Array.isArray(item.reviews?.items)
          ? item.reviews.items.slice(0, 3).map((review) => ({
            text: review.text || review.comment || null,
            rating: review.rating ?? null,
          })).filter((review) => review.text)
          : [],
      };
    })
    .filter(Boolean)
    .sort((a, b) => a.distance_meters - b.distance_meters);

  const nearestDistanceFrom = (from, items) => items
    .map((item) => item.point ? distanceMeters(from, item.point) : null)
    .filter((value) => value != null)
    .sort((a, b) => a - b)[0] ?? null;

  const countWithin = (from, items, radius) => items.reduce(
    (count, item) => count + (item.point && distanceMeters(from, item.point) <= radius ? 1 : 0),
    0,
  );

  // Keep these fields per competitor so the UI can explain the local context
  // instead of showing one aggregate parking/stops number for the whole area.
  const competitorDetails = competitors.map((item) => ({
    ...item,
    nearest_parking_meters: nearestDistanceFrom(item.point, parking),
    parking_within_500m: countWithin(item.point, parking, 500),
    nearest_transport_meters: nearestDistanceFrom(
      item.point,
      transportItems.map((transport) => ({ point: pointOf(transport) })).filter((transport) => transport.point),
    ),
    transport_stops_within_500m: countWithin(
      item.point,
      transportItems.map((transport) => ({ point: pointOf(transport) })).filter((transport) => transport.point),
      500,
    ),
    traffic_index: null,
    traffic_data_available: false,
    traffic_note: '2GIS public Catalog API does not expose per-business pedestrian traffic.',
    schedule_available: Boolean(item.schedule),
  }));

  // 2GIS's public Catalog API does not expose the paid Pro pedestrian dataset.
  // Until that dataset is enabled, this is a clearly-labelled dynamic estimate
  // based on live nearby places and transport stops, never a fabricated count.
  const pedestrianTrafficEstimate = Math.round(
    clamp(20 + totalNearby * 1.5 + transportCount * 3 + competitors.length * 1.2, 0, 100),
  );
  const accessibility = Math.round(clamp(30 + transportCount * 12 + totalNearby * 0.7, 0, 100));
  const competition = Math.round(clamp(100 - competitors500m.length * 9, 0, 100));
  const score = Math.round(accessibility * 0.55 + competition * 0.45);
  const nearestTransport = transportItems
    .map((item) => pointOf(item) ? distanceMeters(point, pointOf(item)) : null)
    .filter((value) => value != null)
    .sort((a, b) => a - b)[0] ?? null;
  const nearestMagnet = publicPlaceItems
    .map((item) => pointOf(item) ? {
      name: item.name || item.full_name || 'Nearby place',
      distance_meters: distanceMeters(point, pointOf(item)),
    } : null)
    .filter(Boolean)
    .sort((a, b) => a.distance_meters - b.distance_meters)[0] ?? null;
  const nearbyPlaces = publicPlaceItems
    .map((item) => {
      const itemPoint = pointOf(item);
      if (!itemPoint) return null;
      return {
        id: item.id?.toString() || null,
        name: item.name || item.full_name || 'Nearby place',
        point: itemPoint,
        distance_meters: distanceMeters(point, itemPoint),
        kind: 'place',
      };
    })
    .filter(Boolean)
    .sort((a, b) => a.distance_meters - b.distance_meters);
  const transportStops = detailedTransportItems.map((item) => ({
    id: item.id?.toString() || null,
    name: item.name || item.full_name || 'Остановка',
    point: pointOf(item),
    distance_meters: pointOf(item) ? distanceMeters(point, pointOf(item)) : null,
    kind: 'transport',
    address: item.address_name || item.full_name || '',
    schedule: item.schedule || null,
    description: item.description || null,
  })).filter((item) => item.point);

  return {
    success: true,
    source: geocoded.source,
    updated_at: new Date().toISOString(),
    address: geocoded.address,
    point,
    score,
    pedestrian_traffic: null,
    pedestrian_traffic_estimate: pedestrianTrafficEstimate,
    pedestrian_traffic_unit: 'unavailable_public_api',
    pedestrian_traffic_source: 'not_available_in_public_2gis_catalog',
    pedestrian_traffic_note: 'Real pedestrian counts require the 2GIS Pro pedestrian dataset; the estimate is shown separately.',
    competitors_500m: competitors500m.length,
    competitors_1km: competitors.length,
    nearest_competitor_meters: nearest,
    accessibility_score: accessibility,
    competition_score: competition,
    business_query: businessQuery,
    competitors: competitorDetails,
    transport_stops_1km: transportCount,
    transport_stops: transportStops,
    nearby_places: nearbyPlaces,
    parking_1km: parking.length,
    parking,
    nearby_places_1km: totalNearby,
    analysis_quality: {
      source: '2GIS Catalog API',
      geocoded_point: true,
      competitor_count_is_live: true,
      competitor_details_loaded: detailedCompetitorItems.length > 0,
      pedestrian_hourly_data_available: false,
      note: 'Counts, distances and nearby objects are live catalog results; pedestrian hourly data requires 2GIS Pro.',
    },
    insights: {
      digital_noise: {
        review_total: reviewTotal,
        leaders: reviewLeaders.slice(0, 4).map((item) => ({
          name: item.name,
          review_count: Number(item.review_count || 0),
          distance_meters: item.distance_meters,
        })),
        period_days: null,
        source: '2GIS current review totals',
        note: '2GIS Catalog API does not provide a reliable public 30-day review delta.',
      },
      peak_comparison: {
        schedule_available_for: scheduleAvailable,
        competitors_sample: competitors.length,
        comparison_available: scheduleAvailable > 0,
        pedestrian_index: null,
        pedestrian_index_estimate: pedestrianTrafficEstimate,
        source: scheduleAvailable > 0 ? '2GIS schedules + live place index' : 'live place index',
      },
      location_magnets: {
        nearest_transport_meters: nearestTransport,
        nearest_place_name: nearestMagnet?.name ?? null,
        nearest_place_meters: nearestMagnet?.distance_meters ?? null,
        competitor_distance_meters: nearest,
        source: '2GIS nearby places and transport stops',
      },
    },
  };
}
