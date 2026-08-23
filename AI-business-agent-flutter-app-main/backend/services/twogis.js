import axios from 'axios';

const CATALOG_URL = 'https://catalog.api.2gis.com';

const BUSINESS_QUERIES = [
  { match: ['ictimai iaşə', 'iaşə', 'restaurant', 'kafe', 'cafe'], query: 'кафе ресторан' },
  { match: ['məhsul', 'pərakəndə', 'market', 'supermarket'], query: 'магазин супермаркет' },
  { match: ['gözəllik', 'beauty'], query: 'салон красоты' },
  { match: ['təbabət', 'medical', 'klinika', 'aptek'], query: 'клиника аптека' },
  { match: ['avtoservis', 'auto', 'car'], query: 'автосервис' },
  { match: ['qonaq evi', 'mehmanxana', 'hotel'], query: 'гостиница отель' },
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
    throw new Error(response.data?.meta?.error_message || `2GIS API error ${code}`);
  }
  return response;
}

async function geocode(address, key) {
  const response = await catalogGet(
    '/3.0/items/geocode',
    {
      q: address,
      fields: 'items.point,items.address,items.adm_div',
      page_size: 5,
    },
    key,
  );
  const item = itemsFrom(response).find((candidate) => pointOf(candidate));
  if (!item) throw new Error('2GIS ünvanı xəritədə tapa bilmədi');
  return {
    item,
    point: pointOf(item),
    address: item.full_name || item.address_name || address,
  };
}

async function nearby(key, point, query, type = 'branch') {
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
        fields: 'items.point,items.address,items.rubrics',
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

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

export async function analyze2GisLocation({ address, city, businessType }) {
  const key = process.env.TWOGIS_API_KEY;
  if (!key) throw new Error('TWOGIS_API_KEY konfiqurasiya edilməyib');

  const geocoded = await geocode(address || city, key);
  const point = geocoded.point;
  const businessQuery = normalizeBusinessQuery(businessType);

  const [competitorItems, transportItems, publicPlaceItems] = await Promise.all([
    nearby(key, point, businessQuery),
    nearby(key, point, 'остановка общественного транспорта', 'station'),
    nearby(key, point, 'магазин кафе аптека', 'branch'),
  ]);

  const competitors = competitorItems
    .map((item) => {
      const itemPoint = pointOf(item);
      if (!itemPoint) return null;
      return {
        id: item.id?.toString() || null,
        name: item.name || item.full_name || '2GIS obyekt',
        address: item.address_name || item.full_name || '',
        point: itemPoint,
        distance_meters: distanceMeters(point, itemPoint),
      };
    })
    .filter(Boolean)
    .sort((a, b) => a.distance_meters - b.distance_meters);

  const competitors500m = competitors.filter((item) => item.distance_meters <= 500);
  const nearest = competitors[0]?.distance_meters ?? null;
  const totalNearby = publicPlaceItems.length;
  const transportCount = transportItems.length;

  // 2GIS's public Catalog API does not expose the paid Pro pedestrian dataset.
  // Until that dataset is enabled, this is a clearly-labelled dynamic estimate
  // based on live nearby places and transport stops, never a fabricated count.
  const pedestrianTraffic = Math.round(
    clamp(25 + totalNearby * 1.5 + transportCount * 8 + competitors.length * 1.2, 0, 100),
  );
  const accessibility = Math.round(clamp(30 + transportCount * 12 + totalNearby * 0.7, 0, 100));
  const competition = Math.round(clamp(100 - competitors500m.length * 9, 0, 100));
  const score = Math.round(pedestrianTraffic * 0.45 + accessibility * 0.35 + competition * 0.2);

  return {
    success: true,
    source: '2GIS Catalog API',
    updated_at: new Date().toISOString(),
    address: geocoded.address,
    point,
    score,
    pedestrian_traffic: pedestrianTraffic,
    pedestrian_traffic_unit: 'index_0_100',
    pedestrian_traffic_source: 'estimated_from_live_2gis_places',
    pedestrian_traffic_note: 'Real pedestrian counts require the 2GIS Pro pedestrian dataset.',
    competitors_500m: competitors500m.length,
    competitors_1km: competitors.length,
    nearest_competitor_meters: nearest,
    accessibility_score: accessibility,
    competition_score: competition,
    business_query: businessQuery,
    competitors,
    transport_stops_1km: transportCount,
    nearby_places_1km: totalNearby,
  };
}
