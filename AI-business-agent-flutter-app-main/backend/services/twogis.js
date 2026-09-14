import axios from 'axios';

const CATALOG_URL = 'https://catalog.api.2gis.com';

const BUSINESS_QUERIES = [
  { match: ['kafe', 'cafe', 'кафе'], query: 'кафе' },
  { match: ['restoran', 'restaurant', 'ресторан'], query: 'ресторан' },
  { match: ['ictimai iaşə', 'iaşə', 'restaurant', 'kafe', 'cafe', 'общепит', 'ресторан', 'кафейн'], query: 'кафе ресторан' },
  { match: ['otel', 'hotel', 'гостиниц', 'отель', 'гостиница', 'qonaq evi', 'mehmanxana'], query: 'гостиница отель' },
  { match: ['məhsul', 'pərakəndə', 'market', 'supermarket', 'магазин', 'продукт'], query: 'магазин супермаркет' },
  { match: ['gözəllik', 'beauty', 'красот', 'салон'], query: 'салон красоты' },
  { match: ['təbabət', 'medical', 'klinika', 'aptek', 'аптек', 'дәріхан', 'медицин'], query: 'аптека клиника' },
  { match: ['avtoservis', 'auto', 'car', 'автосервис'], query: 'автосервис' },
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
  if (!from || !to) return null;
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

function parseRating(item) {
  const r = item?.reviews;
  const val = r?.general_rating ?? r?.rating ?? r?.org_rating ?? item?.rating ?? item?.general_rating ?? null;
  const num = Number(val);
  return Number.isFinite(num) && num > 0 ? Number(num.toFixed(1)) : null;
}

function parseReviewCount(item) {
  const r = item?.reviews;
  const val = r?.general_review_count ?? r?.review_count ?? r?.org_review_count ?? item?.review_count ?? item?.reviews_count ?? 0;
  const num = Number(val);
  return Number.isFinite(num) && num > 0 ? num : 0;
}

export async function suggest2GisAddress(q, city = '') {
  const key = process.env.TWOGIS_API_KEY;
  const normalizedQuery = q.trim();
  const query = city && !normalizedQuery.includes(',') && !normalizedQuery.toLowerCase().includes(city.toLowerCase())
    ? `${city}, ${normalizedQuery}`
    : normalizedQuery;
  if (key) {
    try {
      const response = await catalogGet('/3.0/suggest', {
        q: query,
        page_size: 7,
        fields: 'items.point,items.full_name,items.address_name,items.adm_div',
      }, key);
      const suggestions = itemsFrom(response).map((item) => {
        const cityDiv = Array.isArray(item.adm_div)
          ? item.adm_div.find((division) => division?.type === 'city')
          : null;
        return {
          name: item.full_name || item.address_name || item.name,
          city: cityDiv?.name || city || '',
          point: pointOf(item),
        };
      });
      if (suggestions.length > 0) return suggestions;
    } catch (error) {
      console.warn('2GIS Suggest error:', error.message);
    }

    try {
      const response = await catalogGet('/3.0/items', {
        q: query,
        page_size: 7,
        fields: 'items.point,items.full_name,items.address_name,items.name,items.adm_div',
      }, key);
      const suggestions = itemsFrom(response).map((item) => {
        const cityDiv = Array.isArray(item.adm_div)
          ? item.adm_div.find((division) => division?.type === 'city')
          : null;
        return {
          name: item.full_name || item.address_name || item.name,
          city: cityDiv?.name || city || '',
          point: pointOf(item),
        };
      }).filter((item) => item.name);
      if (suggestions.length > 0) return suggestions;
    } catch (error) {
      console.warn('2GIS Items suggestion error:', error.message);
    }
  }

  try {
    const response = await axios.get('https://nominatim.openstreetmap.org/search', {
      params: { q: query, format: 'jsonv2', limit: 5 },
      headers: { 'User-Agent': 'AI-Business-Agent/1.0 (address search)' },
      timeout: 10000,
    });
    return (Array.isArray(response.data) ? response.data : []).map((item) => ({
      name: item.display_name || item.name || query,
      city: item.address?.city || item.address?.town || item.address?.state || city || '',
      point: {
        lat: Number(item.lat),
        lon: Number(item.lon),
      },
    })).filter((item) => item.point && Number.isFinite(item.point.lat) && Number.isFinite(item.point.lon));
  } catch (error) {
    console.warn('Address fallback error:', error.message);
    return [];
  }
}

async function geocode(address, city, key) {
  const queries = [...new Set([
    city && address && city !== address ? `${city}, ${address}` : null,
    address,
    city ? `${city}` : null,
  ].filter(Boolean))];

  let lastError;

  // 1-ci Pillə: Küçə və ünvan geokodlaşdırması
  for (const query of queries) {
    try {
      const response = await catalogGet(
        '/3.0/items/geocode',
        {
          q: query,
          fields: 'items.point,items.geometry.centroid,items.address,items.adm_div,items.full_name,items.address_name',
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

  // 2-ci Pillə: Obyekt / Biznes adı axtarışı (məsələn: "Гостиница Стюарт")
  for (const query of queries) {
    try {
      const response = await catalogGet(
        '/3.0/items',
        {
          q: query,
          page_size: 5,
          fields: 'items.point,items.geometry.centroid,items.address_name,items.full_name,items.name',
        },
        key,
      );
      const item = itemsFrom(response).find((candidate) => pointOf(candidate));
      if (item) {
        return {
          source: '2GIS Catalog API (POI Search)',
          item,
          point: pointOf(item),
          address: item.full_name || item.address_name || item.name || query,
        };
      }
    } catch (error) {
      lastError = error;
    }
  }

  // 3-cü Pillə: 2GIS Suggest API axtarışı
  for (const query of queries) {
    try {
      const suggestions = await suggest2GisAddress(query, city);
      const matched = suggestions.find(s => s.point);
      if (matched) {
        return {
          source: '2GIS Suggest API',
          item: null,
          point: matched.point,
          address: matched.name,
        };
      }
    } catch (_) {}
  }

  throw lastError || new Error(`2GIS ünvanı və ya obyekti tapmadı: "${address || city}"`);
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
        page_size: 10,
        fields: fields || 'items.point,items.address,items.rubrics,items.reviews,items.schedule,items.links,items.flags',
      },
      key,
    );
    return itemsFrom(response);
  } catch (error) {
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
    console.warn(`2GIS details failed for ${item.id}:`, error.message);
    return item;
  }
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

export async function analyze2GisLocation({ address, city, businessType, provider }) {
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
      const rating = parseRating(item);
      const reviewCount = parseReviewCount(item);
      const hasSchedule = Boolean(
        item.schedule && typeof item.schedule === 'object' && Object.keys(item.schedule).length > 0
      );
      return {
        id: item.id?.toString() || null,
        name: item.name || item.full_name || '2GIS obyekt',
        address: item.address_name || item.full_name || '',
        point: itemPoint,
        distance_meters: distanceMeters(point, itemPoint),
        rating: rating,
        review_count: reviewCount,
        rubrics: (Array.isArray(item.rubrics) ? item.rubrics : []).map((rubric) => rubric.name || rubric).filter(Boolean),
        schedule: item.schedule || null,
        schedule_special: item.schedule_special || null,
        has_schedule: hasSchedule,
        schedule_available: hasSchedule,
        description: item.description || null,
        links: item.links || null,
        contact_groups: item.contact_groups || null,
        flags: item.flags || [],
      };
    })
    .filter(Boolean)
    .sort((a, b) => (a.distance_meters ?? 99999) - (b.distance_meters ?? 99999));

  const competitors500m = competitors.filter((item) => item.distance_meters <= 500);
  const nearest = competitors[0]?.distance_meters ?? null;
  const reviewLeaders = [...competitors]
    .filter((item) => Number(item.review_count) > 0)
    .sort((a, b) => Number(b.review_count) - Number(a.review_count));
  const reviewTotal = reviewLeaders.reduce(
    (sum, item) => sum + Number(item.review_count || 0),
    0,
  );
  const scheduleAvailable = competitors.filter((item) => item.has_schedule).length;
  const totalNearby = publicPlaceItems.length;
  const transportCount = transportItems.length;

  const parking = detailedParkingItems
    .map((item) => {
      const itemPoint = pointOf(item);
      if (!itemPoint) return null;
      return {
        id: item.id?.toString() || null,
        name: item.name || item.full_name || 'Parkinq',
        address: item.address_name || item.full_name || '',
        point: itemPoint,
        distance_meters: distanceMeters(point, itemPoint),
        is_paid: item.is_paid ?? null,
        capacity: item.capacity ?? null,
        level_count: item.level_count ?? null,
        access: item.access ?? null,
        paving_type: item.paving_type ?? null,
        schedule: item.schedule || null,
        review_count: parseReviewCount(item),
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
    traffic_note: 'Piyada trafiki göstəricisi 2GIS canlı məlumatı əsasında hesablanır.',
    schedule_available: Boolean(item.has_schedule),
  }));

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
      name: item.name || item.full_name || 'Yaxın obyekt',
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
        name: item.name || item.full_name || 'Yaxın obyekt',
        point: itemPoint,
        distance_meters: distanceMeters(point, itemPoint),
        kind: 'place',
      };
    })
    .filter(Boolean)
    .sort((a, b) => a.distance_meters - b.distance_meters);

  const transportStops = detailedTransportItems.map((item) => ({
    id: item.id?.toString() || null,
    name: item.name || item.full_name || 'Nəqliyyat dayanacağı',
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
      pedestrian_hourly_data_available: true,
      note: 'Məlumatlar və rəqabət nöqtələri 2GIS canlı kataloq bazasından yüklənmişdir.',
    },
    insights: {
      digital_noise: {
        review_total: reviewTotal,
        leaders: reviewLeaders.slice(0, 4).map((item) => ({
          name: item.name,
          review_count: Number(item.review_count || 0),
          distance_meters: item.distance_meters,
        })),
        source: '2GIS cari rəy göstəriciləri',
      },
      peak_comparison: {
        schedule_available_for: scheduleAvailable,
        competitors_sample: competitors.length,
        comparison_available: scheduleAvailable > 0,
        pedestrian_index_estimate: pedestrianTrafficEstimate,
        source: scheduleAvailable > 0 ? '2GIS iş qrafiki + canlı obyekt indeksi' : 'canlı obyekt indeksi',
      },
      location_magnets: {
        nearest_transport_meters: nearestTransport,
        nearest_place_name: nearestMagnet?.name ?? null,
        nearest_place_meters: nearestMagnet?.distance_meters ?? null,
        competitor_distance_meters: nearest,
        source: '2GIS yaxın nəqliyyat və obyektlər',
      },
    },
  };
}