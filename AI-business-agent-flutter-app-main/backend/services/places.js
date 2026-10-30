import axios from 'axios';

/**
 * Unified place search used by the map search box and every address field.
 *
 * Search must never depend on the heavy location-analysis endpoint: a country
 * or city query has to resolve even when 2GIS has no key, is rate limited or
 * is temporarily unavailable. The service therefore merges three sources:
 *
 *   1. A small local gazetteer (countries + main cities in az/ru/kk/en names).
 *   2. The 2GIS Catalog API (addresses and businesses) when a key is present.
 *   3. Nominatim (OpenStreetMap) as the language-aware fallback for anything
 *      the first two do not know.
 *
 * Every provider result is normalised to the same shape so the Flutter client
 * can display it and move the map without knowing where it came from.
 */

const CATALOG_URL = 'https://catalog.api.2gis.com';
const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search';
const USER_AGENT = 'AI-Business-Agent/1.0 (place search)';
const CACHE_TTL_MS = 5 * 60 * 1000;
const CACHE_LIMIT = 300;

const AZ_MAP = {
  ə: 'e',
  ı: 'i',
  ş: 's',
  ç: 'c',
  ü: 'u',
  ö: 'o',
  ğ: 'g',
  İ: 'i',
};
const KZ_CYRILLIC_MAP = {
  қ: 'к',
  ғ: 'г',
  ң: 'н',
  ө: 'о',
  ұ: 'у',
  ү: 'у',
  һ: 'х',
  і: 'и',
  ә: 'а',
  ё: 'е',
};

/** Lowercase, strip diacritics and punctuation so aliases compare reliably. */
export function normalize(value = '') {
  return String(value)
    .toLowerCase()
    .replace(/[əışçüöğİ]/g, (char) => AZ_MAP[char] ?? char)
    .replace(/[қғңөұүһіәё]/g, (char) => KZ_CYRILLIC_MAP[char] ?? char)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9а-я\s-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

const CYRILLIC_RULES = [
  ['shch', 'щ'],
  ['sch', 'щ'],
  ['zh', 'ж'],
  ['kh', 'х'],
  ['ts', 'ц'],
  ['ch', 'ч'],
  ['sh', 'ш'],
  ['yu', 'ю'],
  ['ya', 'я'],
  ['yo', 'ё'],
  ['ye', 'е'],
  ['a', 'а'],
  ['b', 'б'],
  ['c', 'к'],
  ['d', 'д'],
  ['e', 'е'],
  ['f', 'ф'],
  ['g', 'г'],
  ['h', 'х'],
  ['i', 'и'],
  ['j', 'дж'],
  ['k', 'к'],
  ['l', 'л'],
  ['m', 'м'],
  ['n', 'н'],
  ['o', 'о'],
  ['p', 'п'],
  ['q', 'к'],
  ['r', 'р'],
  ['s', 'с'],
  ['t', 'т'],
  ['u', 'у'],
  ['v', 'в'],
  ['w', 'в'],
  ['x', 'х'],
  ['y', 'ы'],
  ['z', 'з'],
];

const SPECIAL_LETTERS = {
  ə: 'ә',
  ı: 'ы',
  ş: 'ш',
  ç: 'ч',
  ü: 'ү',
  ö: 'ө',
  ğ: 'ғ',
};

const WORD_TRANSLITERATIONS = { fitness: 'фитнес' };

function transliterateWord(value) {
  const lower = String(value).toLowerCase();
  let result = '';
  let index = 0;
  while (index < lower.length) {
    const char = lower[index];
    if (SPECIAL_LETTERS[char]) {
      result += SPECIAL_LETTERS[char];
      index += 1;
      continue;
    }
    const rule = CYRILLIC_RULES.find(([latin]) => lower.startsWith(latin, index));
    if (rule) {
      result += rule[1];
      index += rule[0].length;
      continue;
    }
    result += char;
    index += 1;
  }
  return result;
}

/**
 * Latin place/business names in Kazakhstan are almost always registered in
 * Russian. A deterministic transliteration lets "Olzha" find "ОЛЖА" even in
 * OpenStreetMap, where only the Cyrillic name exists.
 */
export function transliterateToCyrillic(value = '') {
  return String(value)
    .split(/(\s+)/)
    .map((part) => {
      const known = WORD_TRANSLITERATIONS[normalize(part)];
      if (known) return known;
      return transliterateWord(part);
    })
    .join('');
}

export function transliterationVariants(value = '') {
  const base = transliterateToCyrillic(value);
  const variants = new Set();
  if (base.endsWith('ы') || base.endsWith('и')) {
    variants.add(`${base.slice(0, -1)}й`);
    variants.add(base.slice(0, -1));
  }
  variants.add(base);
  return [...variants].filter(Boolean);
}

const CATEGORY_WORDS = new Set([
  'fitness',
  'gym',
  'club',
  'sport',
  'cafe',
  'coffee',
  'restaurant',
  'hotel',
  'shop',
  'store',
  'market',
  'mall',
  'center',
  'centre',
  'фитнес',
  'клуб',
  'спортзал',
  'спорт',
  'кафе',
  'кофейня',
  'ресторан',
  'гостиница',
  'отель',
  'магазин',
  'центр',
]);

/** "Olzha fitness club" -> "Olzha" by removing generic category words. */
export function brandOnly(query = '') {
  const words = String(query).split(/\s+/).filter(Boolean);
  const kept = words.filter((word) => !CATEGORY_WORDS.has(normalize(word)));
  return kept.length > 0 && kept.length < words.length ? kept.join(' ') : '';
}

function city(id, name, aliases, lat, lon, countryCode) {
  return { id, name, aliases, lat, lon, countryCode };
}

const COUNTRIES = [
  {
    code: 'KZ',
    names: { az: 'Qazaxıstan', en: 'Kazakhstan', ru: 'Казахстан', kk: 'Қазақстан' },
    aliases: ['qazaxistan', 'qazaqstan', 'kazakhstan', 'kazakstan', 'казахстан', 'казакстан'],
    lat: 48.0196,
    lon: 66.9237,
    bbox: { min_lat: 40.56, min_lon: 46.49, max_lat: 55.44, max_lon: 87.31 },
    zoom: 4.6,
    cities: [
      city('astana', 'Astana', ['astana', 'nur-sultan', 'nursultan', 'астана', 'нур-султан', 'астана'], 51.1605, 71.4704, 'KZ'),
      city('almaty', 'Almaty', ['almaty', 'almati', 'алматы', 'алма-ата', 'alma-ata', 'алматы'], 43.2389, 76.8897, 'KZ'),
      city('shymkent', 'Shymkent', ['shymkent', 'shimkent', 'шимкент', 'чимкент'], 42.3417, 69.5901, 'KZ'),
      city('aktau', 'Aktau', ['aktau', 'aqtau', 'актау', 'шевченко'], 43.6353, 51.1682, 'KZ'),
      city('atyrau', 'Atyrau', ['atyrau', 'атырау', 'гураев', 'guryev'], 47.0945, 51.9238, 'KZ'),
      city('karaganda', 'Karaganda', ['karaganda', 'qaragandy', 'караганда'], 49.8047, 73.1094, 'KZ'),
      city('aktobe', 'Aktobe', ['aktobe', 'aqtobe', 'актобе', 'актюбинск'], 50.2839, 57.1670, 'KZ'),
      city('taraz', 'Taraz', ['taraz', 'тараз', 'джамбул', 'zhambyl'], 42.9000, 71.3667, 'KZ'),
      city('pavlodar', 'Pavlodar', ['pavlodar', 'павлодар'], 52.2873, 76.9674, 'KZ'),
      city('oskemen', 'Oskemen', ['oskemen', 'ust-kamenogorsk', 'усть-каменогорск'], 49.9483, 82.6275, 'KZ'),
      city('semey', 'Semey', ['semey', 'семей', 'семипалатинск'], 50.4111, 80.2275, 'KZ'),
      city('turkistan', 'Turkistan', ['turkistan', 'туркестан'], 43.2973, 68.2517, 'KZ'),
      city('kostanay', 'Kostanay', ['kostanay', 'костанай', 'кустанай'], 53.2144, 63.6246, 'KZ'),
      city('kyzylorda', 'Kyzylorda', ['kyzylorda', 'кызылорда'], 44.8488, 65.4823, 'KZ'),
    ],
  },
  {
    code: 'AZ',
    names: { az: 'Azərbaycan', en: 'Azerbaijan', ru: 'Азербайджан', kk: 'Әзірбайжан' },
    aliases: ['azerbaycan', 'azerbaijan', 'азербайджан'],
    lat: 40.1431,
    lon: 47.5769,
    bbox: { min_lat: 38.39, min_lon: 44.79, max_lat: 41.91, max_lon: 50.37 },
    zoom: 6.4,
    cities: [
      city('baku', 'Baku', ['baku', 'bakı', 'баку'], 40.4093, 49.8671, 'AZ'),
      city('ganja', 'Ganja', ['ganja', 'gence', 'гянджа'], 40.6828, 46.3606, 'AZ'),
      city('sumgait', 'Sumgait', ['sumgait', 'sumqayit', 'сумгаит'], 40.5897, 49.6686, 'AZ'),
    ],
  },
  {
    code: 'UZ',
    names: { az: 'Özbəkistan', en: 'Uzbekistan', ru: 'Узбекистан', kk: 'Өзбекстан' },
    aliases: ['ozbekistan', 'uzbekistan', 'узбекистан'],
    lat: 41.3775,
    lon: 64.5853,
    bbox: { min_lat: 37.18, min_lon: 55.99, max_lat: 45.59, max_lon: 73.13 },
    zoom: 5,
    cities: [
      city('tashkent', 'Tashkent', ['tashkent', 'ташкент'], 41.2995, 69.2401, 'UZ'),
      city('samarkand', 'Samarkand', ['samarkand', 'самарканд'], 39.6270, 66.9750, 'UZ'),
    ],
  },
  {
    code: 'KG',
    names: { az: 'Qırğızıstan', en: 'Kyrgyzstan', ru: 'Кыргызстан', kk: 'Қырғызстан' },
    aliases: ['qirgizistan', 'kyrgyzstan', 'kirgizstan', 'кыргызстан', 'киргизия'],
    lat: 41.2044,
    lon: 74.7661,
    bbox: { min_lat: 39.17, min_lon: 69.26, max_lat: 43.26, max_lon: 80.28 },
    zoom: 5.6,
    cities: [city('bishkek', 'Bishkek', ['bishkek', 'бишкек'], 42.8746, 74.5698, 'KG')],
  },
  {
    code: 'GE',
    names: { az: 'Gürcüstan', en: 'Georgia', ru: 'Грузия', kk: 'Грузия' },
    aliases: ['gurcustan', 'georgia', 'грузия'],
    lat: 42.3154,
    lon: 43.3569,
    bbox: { min_lat: 41.05, min_lon: 40.0, max_lat: 43.59, max_lon: 46.74 },
    zoom: 6.2,
    cities: [
      city('tbilisi', 'Tbilisi', ['tbilisi', 'тифлис', 'тбилиси'], 41.7151, 44.8271, 'GE'),
      city('batumi', 'Batumi', ['batumi', 'батуми'], 41.6168, 41.6367, 'GE'),
    ],
  },
  {
    code: 'RU',
    names: { az: 'Rusiya', en: 'Russia', ru: 'Россия', kk: 'Ресей' },
    aliases: ['rusiya', 'russia', 'россия'],
    lat: 61.524,
    lon: 105.3188,
    bbox: { min_lat: 41.19, min_lon: 19.6, max_lat: 81.86, max_lon: 180 },
    zoom: 3.2,
    cities: [
      city('moscow', 'Moscow', ['moscow', 'москва'], 55.7558, 37.6173, 'RU'),
      city('saint-petersburg', 'Saint Petersburg', ['saint petersburg', 'петербург', 'спб'], 59.9343, 30.3351, 'RU'),
      city('kazan', 'Kazan', ['kazan', 'казань'], 55.7963, 49.1088, 'RU'),
    ],
  },
  {
    code: 'TR',
    names: { az: 'Türkiyə', en: 'Turkey', ru: 'Турция', kk: 'Түркия' },
    aliases: ['turkiye', 'turkey', 'турция'],
    lat: 38.9637,
    lon: 35.2433,
    bbox: { min_lat: 35.82, min_lon: 25.66, max_lat: 42.11, max_lon: 44.82 },
    zoom: 4.8,
    cities: [
      city('istanbul', 'Istanbul', ['istanbul', 'стамбул'], 41.0082, 28.9784, 'TR'),
      city('ankara', 'Ankara', ['ankara', 'анкара'], 39.9334, 32.8597, 'TR'),
    ],
  },
  {
    code: 'TM',
    names: { az: 'Türkmənistan', en: 'Turkmenistan', ru: 'Туркменистан', kk: 'Түрікменстан' },
    aliases: ['turkmenistan', 'туркменистан'],
    lat: 38.9697,
    lon: 59.5563,
    bbox: { min_lat: 35.14, min_lon: 52.5, max_lat: 42.8, max_lon: 66.68 },
    zoom: 5.2,
    cities: [city('ashgabat', 'Ashgabat', ['ashgabat', 'ашхабад'], 37.9601, 58.3261, 'TM')],
  },
  {
    code: 'TJ',
    names: { az: 'Tacikistan', en: 'Tajikistan', ru: 'Таджикистан', kk: 'Тәжікстан' },
    aliases: ['tacikistan', 'tajikistan', 'таджикистан'],
    lat: 38.861,
    lon: 71.2761,
    bbox: { min_lat: 36.67, min_lon: 67.34, max_lat: 41.04, max_lon: 75.18 },
    zoom: 5.6,
    cities: [city('dushanbe', 'Dushanbe', ['dushanbe', 'душанбе'], 38.5598, 68.7870, 'TJ')],
  },
  {
    code: 'AM',
    names: { az: 'Ermənistan', en: 'Armenia', ru: 'Армения', kk: 'Армения' },
    aliases: ['ermenistan', 'armenia', 'армения'],
    lat: 40.0691,
    lon: 45.0382,
    bbox: { min_lat: 38.84, min_lon: 43.45, max_lat: 41.3, max_lon: 46.63 },
    zoom: 7,
    cities: [city('yerevan', 'Yerevan', ['yerevan', 'ереван'], 40.1792, 44.4991, 'AM')],
  },
  {
    code: 'BY',
    names: { az: 'Belarus', en: 'Belarus', ru: 'Беларусь', kk: 'Беларусь' },
    aliases: ['belarus', 'беларусь', 'белоруссия'],
    lat: 53.7098,
    lon: 27.9534,
    bbox: { min_lat: 51.26, min_lon: 23.18, max_lat: 56.17, max_lon: 32.72 },
    zoom: 5.4,
    cities: [city('minsk', 'Minsk', ['minsk', 'минск'], 53.9006, 27.5590, 'BY')],
  },
];

const ALL_CITIES = COUNTRIES.flatMap((country) =>
  country.cities.map((item) => ({ ...item, country })),
);

// Pre-normalise the gazetteer once so request handling stays cheap.
const COUNTRY_INDEX = COUNTRIES.map((country) => ({
  country,
  aliases: [...new Set(country.aliases.map(normalize))].filter(Boolean),
}));
const CITY_INDEX = ALL_CITIES.map((item) => ({
  item,
  aliases: [...new Set([item.id, item.name, ...item.aliases].map(normalize))].filter(Boolean),
}));

function bboxOfCountry(country) {
  return country.bbox;
}

function bboxOfNominatim(item) {
  const raw = item?.boundingbox;
  if (!Array.isArray(raw) || raw.length !== 4) return null;
  const [south, north, west, east] = raw.map((value) => Number(value));
  if ([south, north, west, east].some((value) => !Number.isFinite(value))) return null;
  return { min_lat: south, min_lon: west, max_lat: north, max_lon: east };
}

function validPoint(lat, lon) {
  const parsedLat = Number(lat);
  const parsedLon = Number(lon);
  if (!Number.isFinite(parsedLat) || !Number.isFinite(parsedLon)) return null;
  if (parsedLat < -90 || parsedLat > 90 || parsedLon < -180 || parsedLon > 180) return null;
  return { lat: parsedLat, lon: parsedLon };
}

function pointOf(item) {
  const point = item?.point || item?.geometry?.centroid;
  if (!point) return null;
  return validPoint(point.lat, point.lon);
}

function distanceMeters(first, second) {
  if (!first || !second) return Number.POSITIVE_INFINITY;
  const earthRadius = 6371000;
  const lat1 = (first.lat * Math.PI) / 180;
  const lat2 = (second.lat * Math.PI) / 180;
  const dLat = ((second.lat - first.lat) * Math.PI) / 180;
  const dLon = ((second.lon - first.lon) * Math.PI) / 180;
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

const TYPE_LABELS = {
  az: { country: 'Ölkə', city: 'Şəhər', address: 'Ünvan', poi: 'Məkan' },
  en: { country: 'Country', city: 'City', address: 'Address', poi: 'Place' },
  ru: { country: 'Страна', city: 'Город', address: 'Адрес', poi: 'Место' },
  kk: { country: 'Ел', city: 'Қала', address: 'Мекенжай', poi: 'Орын' },
};

function typeLabel(type, language = 'az') {
  return TYPE_LABELS[language]?.[type] || TYPE_LABELS.az[type] || '';
}

/** Pick a sensible fallback zoom from the result's bounding box. */
function zoomForBbox(bbox, type) {
  if (!bbox) return null;
  const span = Math.max(
    bbox.max_lat - bbox.min_lat,
    (bbox.max_lon - bbox.min_lon) * 0.6,
  );
  if (span > 20) return 3.5;
  if (span > 8) return 4.8;
  if (span > 3) return 6;
  if (span > 1) return 7.5;
  if (span > 0.3) return 9.5;
  return type === 'address' || type === 'poi' ? 16 : 11;
}

function makeResult({
  id,
  name,
  subtitle = '',
  type,
  lat,
  lon,
  bbox = null,
  city = '',
  zoom = null,
  source,
  countryCode = null,
  language = 'az',
}) {
  const point = validPoint(lat, lon);
  if (!point) return null;
  return {
    id,
    name,
    subtitle: subtitle || typeLabel(type, language),
    type,
    lat: point.lat,
    lon: point.lon,
    point,
    bbox,
    city: city || '',
    country_code: countryCode,
    zoom:
      zoom ??
      zoomForBbox(bbox, type) ??
      (type === 'country' ? 4.8 : type === 'city' ? 11 : type === 'address' ? 16 : 17),
    source,
  };
}

const CITY_COUNT_WORDS = { az: 'şəhər', en: 'cities', ru: 'городов', kk: 'қала' };

function countryResult(country, language = 'az') {
  const name = country.names[language] || country.names.az || country.names.en;
  return makeResult({
    id: `country:${country.code}`,
    name,
    subtitle: `${country.cities.length} ${CITY_COUNT_WORDS[language] || CITY_COUNT_WORDS.az}`,
    type: 'country',
    lat: country.lat,
    lon: country.lon,
    bbox: bboxOfCountry(country),
    zoom: country.zoom,
    source: 'gazetteer',
    countryCode: country.code,
  });
}

function cityResult(cityEntry, language = 'az') {
  return makeResult({
    id: `city:${cityEntry.id}`,
    name: cityEntry.name,
    subtitle: (cityEntry.country?.names?.[language] || cityEntry.country?.names?.az || ''),
    type: 'city',
    lat: cityEntry.lat,
    lon: cityEntry.lon,
    city: cityEntry.name,
    zoom: 11,
    source: 'gazetteer',
    countryCode: cityEntry.country?.code || null,
    language,
  });
}

function findCountry(normalizedQuery) {
  const words = new Set(normalizedQuery.split(' '));
  for (const entry of COUNTRY_INDEX) {
    if (entry.aliases.some((alias) => normalizedQuery === alias)) {
      return { country: entry.country, consumed: entry.aliases };
    }
    const matched = entry.aliases.find((alias) => words.has(alias));
    if (matched) return { country: entry.country, consumed: entry.aliases };
  }
  return null;
}

function findCities(normalizedQuery) {
  return CITY_INDEX.filter((entry) =>
    entry.aliases.some((alias) => {
      if (alias.length < 3) return normalizedQuery === alias;
      return normalizedQuery === alias || normalizedQuery.startsWith(`${alias} `);
    }),
  ).map((entry) => entry.item);
}

function searchGazetteer(query, countryHit, language = 'az') {
  const normalizedQuery = normalize(query);
  const results = [];
  if (countryHit) {
    const country = countryHit.country;
    results.push(countryResult(country, language));
    // Tokens left after the country name ("Qazaxıstan Almatı") narrow the
    // city list; a bare country name lists its main cities so the map has
    // places to jump to instead of a single pin in the middle of nowhere.
    const consumed = new Set(countryHit.consumed.flatMap((alias) => alias.split(' ')));
    const remainder = normalizedQuery
      .split(' ')
      .filter((word) => word && !consumed.has(word))
      .join(' ');
    cityIndexEntriesForCountry(country)
      .filter((cityEntry) => {
        if (!remainder) return true;
        return [cityEntry.id, cityEntry.name, ...cityEntry.aliases]
          .map(normalize)
          .some((alias) => alias.includes(remainder) || remainder.includes(alias));
      })
      .forEach((cityEntry) => {
        results.push(cityResult(cityEntry, language));
      });
  }
  findCities(normalizedQuery).forEach((cityEntry) => {
    results.push(cityResult(cityEntry, language));
  });
  return results;
}

/** True when the whole query is just a known city name/alias. */
function isExactCityQuery(normalizedQuery) {
  return CITY_INDEX.some((entry) => entry.aliases.includes(normalizedQuery));
}

function cityIndexEntriesForCountry(country) {
  return ALL_CITIES.filter((entry) => entry.country.code === country.code).slice(0, 8);
}

function dedupe(results) {
  const kept = [];
  for (const candidate of results) {
    if (!candidate) continue;
    const duplicate = kept.some((existing) => {
      const distance = distanceMeters(existing.point, candidate.point);
      if (existing.id && candidate.id && existing.id === candidate.id) {
        return true;
      }
      if (normalize(existing.name) === normalize(candidate.name)) {
        return distance < 50;
      }
      // The same city arrives from the gazetteer ("Almaty") and OSM
      // ("Almatı"); keep the first, drop the near-identical duplicate.
      const broad = ['country', 'city'];
      if (broad.includes(existing.type) && broad.includes(candidate.type)) {
        return distance < 25000;
      }
      return false;
    });
    if (!duplicate) kept.push(candidate);
  }
  return kept;
}

function normalizeNominatim(item, language = 'az') {
  const point = validPoint(item?.lat, item?.lon);
  if (!point) return null;
  const address = item?.address || {};
  const name = item?.name || item?.display_name?.split(',')[0] || 'Məkan';
  const subtitleParts = [
    ...new Set(
      [
        address.road || address.pedestrian,
        address.suburb || address.neighbourhood,
        address.city || address.town || address.village || address.municipality,
        address.state || address.region,
        address.country,
      ]
        .filter(
          (part) => part && String(part).trim() && String(part).trim() !== name,
        )
        .map((part) => String(part).trim()),
    ),
  ];
  const addresstype = (item?.addresstype || item?.type || '').toLowerCase();
  let type = 'poi';
  if (addresstype === 'country') type = 'country';
  else if (
    ['city', 'town', 'village', 'municipality', 'state', 'region', 'province', 'county', 'district', 'suburb'].includes(addresstype)
  )
    type = 'city';
  else if (
    ['house_number', 'house', 'road', 'street', 'residential', 'neighbourhood', 'postcode', 'building', 'address', 'pedestrian'].includes(addresstype)
  )
    type = 'address';
  return makeResult({
    id: `osm:${item.osm_type || 'node'}:${item.osm_id || `${point.lat},${point.lon}`}`,
    name,
    subtitle: subtitleParts.slice(0, 3).join(', '),
    type,
    lat: point.lat,
    lon: point.lon,
    bbox: bboxOfNominatim(item),
    city: address.city || address.town || address.village || '',
    zoom: type === 'country' ? 4.6 : type === 'city' ? 11 : type === 'address' ? 16 : 17,
    source: 'nominatim',
    countryCode: (address.country_code || '').toUpperCase() || null,
    language,
  });
}

const cache = new Map();

function cacheGet(key) {
  const hit = cache.get(key);
  if (!hit) return null;
  if (Date.now() - hit.at > CACHE_TTL_MS) {
    cache.delete(key);
    return null;
  }
  return hit.value;
}

function cacheSet(key, value) {
  if (cache.size >= CACHE_LIMIT) {
    const oldest = cache.keys().next().value;
    if (oldest) cache.delete(oldest);
  }
  cache.set(key, { at: Date.now(), value });
}

async function twoGisSuggest(query, city, key, { itemsOnly = false } = {}) {
  if (!key) return [];
  const scoped = city && !normalize(query).includes(normalize(city)) ? `${city}, ${query}` : query;
  const fields = 'items.point,items.full_name,items.address_name,items.name,items.adm_div';
  const calls = [
    { path: '/3.0/suggests', params: { q: scoped, page_size: 10, fields } },
    { path: '/3.0/items', params: { q: scoped, page_size: 10, fields } },
  ];
  const selectedCalls = itemsOnly ? calls.slice(1) : calls;
  const batches = await Promise.all(selectedCalls.map(async (call) => {
    try {
      const response = await axios.get(`${CATALOG_URL}${call.path}`, {
        params: { ...call.params, key },
        timeout: 8000,
      });
      const code = response.data?.meta?.code;
      if (code && code !== 200) return [];
      const items = response.data?.result?.items || response.data?.result?.data || [];
      return items
        .map((item) => {
          const point = pointOf(item);
          if (!point) return null;
          const cityDiv = Array.isArray(item.adm_div)
            ? item.adm_div.find((division) => division?.type === 'city')
            : null;
          const name = item.full_name || item.address_name || item.name;
          if (!name) return null;
          const isAddress = Boolean(item.address_name && !item.name);
          return makeResult({
            id: `2gis:${item.id || `${point.lat},${point.lon}`}`,
            name: item.name || item.address_name || name,
            subtitle: [item.address_name, cityDiv?.name || city].filter(Boolean).join(', '),
            type: isAddress ? 'address' : 'poi',
            lat: point.lat,
            lon: point.lon,
            city: cityDiv?.name || city || '',
            source: '2gis',
          });
        })
        .filter(Boolean);
    } catch (error) {
      console.warn(`2GIS place search failed (${call.path}):`, error.message);
      return [];
    }
  }));
  return dedupe(batches.flat());
}

async function nominatimSearch(query, { city = '', countryCode = '', limit = 8, language = 'az' } = {}) {
  const acceptLanguage = countryCode === 'KZ'
    ? language === 'ru'
      ? 'ru,kk,en'
      : language === 'en'
        ? 'en,kk,ru'
        : 'kk,ru,en'
    : language === 'ru'
      ? 'ru,az,en'
      : language === 'kk'
        ? 'kk,ru,en'
        : language === 'en'
          ? 'en,ru,az'
          : 'az,ru,en';
  const params = {
    q: city && !normalize(query).includes(normalize(city)) ? `${city}, ${query}` : query,
    format: 'jsonv2',
    addressdetails: 1,
    limit,
    'accept-language': acceptLanguage,
  };
  if (countryCode) params.countrycodes = countryCode.toLowerCase();
  try {
    const response = await axios.get(NOMINATIM_URL, {
      params,
      headers: { 'User-Agent': USER_AGENT, Accept: 'application/json' },
      timeout: 10000,
    });
    return (Array.isArray(response.data) ? response.data : [])
      .map((item) => normalizeNominatim(item, language))
      .filter(Boolean);
  } catch (error) {
    console.warn('Nominatim place search failed:', error.message);
    return [];
  }
}

/**
 * Search countries, cities, addresses and businesses.
 * Returns normalised results ordered by usefulness for the map UI.
 */
export async function searchPlaces({
  q,
  city = '',
  countryCode: requestedCountryCode = '',
  types = [],
  language = 'az',
  limit = 12,
} = {}) {
  const query = String(q || '').trim();
  if (query.length < 2) return [];
  const languageCode = ['az', 'en', 'ru', 'kk'].includes(language) ? language : 'az';
  const normalizedQuery = normalize(query);
  const countryHit = findCountry(normalizedQuery);
  const requestedTypes = new Set(
    (Array.isArray(types) ? types : String(types || '').split(','))
      .map((type) => String(type).trim())
      .filter((type) => ['country', 'city', 'address', 'poi'].includes(type)),
  );
  const areaOnlySearch =
    requestedTypes.size > 0 &&
    [...requestedTypes].every((type) => type === 'city' || type === 'country');
  const queryCityHit = findCities(normalizedQuery)[0];
  const selectedCityHit = findCities(normalize(city))[0];
  const country =
    countryHit?.country ||
    queryCityHit?.country ||
    (areaOnlySearch ? null : selectedCityHit?.country);
  const countryCode = String(
    countryHit?.country?.code ||
      queryCityHit?.country?.code ||
      (areaOnlySearch ? '' : requestedCountryCode) ||
      (areaOnlySearch ? '' : selectedCityHit?.country?.code) ||
      '',
  ).trim().toUpperCase();
  const resultLimit = Math.max(1, Math.min(Number(limit) || 12, 12));
  const key = process.env.TWOGIS_API_KEY;
  const cacheKey = `search:${normalizedQuery}|${normalize(city)}|${countryCode}|${[...requestedTypes].sort().join(',')}|${languageCode}`;
  const cached = cacheGet(cacheKey);
  if (cached) return cached;

  const staticResults = searchGazetteer(query, countryHit, languageCode);
  // Country and city names are already explicit in the query; don't narrow
  // those lookups by the previously selected search area.
  const cityScope =
    staticResults.length > 0 || areaOnlySearch
      ? ''
      : String(city || '').trim();

  const skipOsm = Boolean(countryHit) || isExactCityQuery(normalizedQuery);
  const hasStatic = staticResults.length >= 2;

  const collect = async (
    variant,
    { osmOnly = false, skipOsmFallback = false, itemsOnly = false } = {},
  ) => {
    const gisResults = osmOnly || requestedTypes.size > 0
      ? []
      : await twoGisSuggest(variant, cityScope, key, { itemsOnly });
    if (
      skipOsmFallback ||
      skipOsm ||
      hasStatic ||
      (!osmOnly && requestedTypes.size === 0 && gisResults.length >= 3)
    ) {
      return gisResults;
    }
    const osmResults = await nominatimSearch(variant, {
      city: cityScope,
      countryCode,
      limit,
      language: languageCode,
    });
    return [...gisResults, ...osmResults];
  };

  let merged = dedupe([...staticResults, ...(await collect(query))]);
  const brand = brandOnly(query);
  const categoryRoot = brand || query;
  const normalizedRoot = normalize(categoryRoot);
  const meaningfulQueryTokens = normalize(query)
    .split(' ')
    .filter((token) => token.length >= 3 && !CATEGORY_WORDS.has(token));
  const categoryTerms = countryCode === 'KZ'
    ? ['магазин', 'market', 'рынок']
    : countryCode === 'AZ'
      ? ['mağaza', 'market', 'магазин']
      : languageCode === 'ru'
        ? ['магазин', 'рынок', 'business']
        : languageCode === 'kk'
          ? ['дүкен', 'маркет', 'business']
          : languageCode === 'az'
            ? ['mağaza', 'market', 'business']
            : ['shop', 'store', 'business'];
  const isBrandQuery =
    meaningfulQueryTokens.length > 0 &&
    !isExactCityQuery(normalizedQuery) &&
    requestedTypes.size === 0 &&
    !countryHit;
  const variants =
    /[a-z]/i.test(query) &&
    (!countryCode || ['KZ', 'AZ', 'RU', 'KG', 'UZ', 'GE', 'AM', 'BY', 'TJ', 'TM'].includes(countryCode))
      ? [
          ...transliterationVariants(query),
          ...(brand ? transliterationVariants(brand) : []),
        ]
      : [];
  const variantQueries = [...new Set(variants)].filter(
    (variant) => normalize(variant) !== normalizedQuery,
  );
  const categoryQueries = isBrandQuery && !normalizedRoot.includes(' ')
    ? categoryTerms.map((term) => `${categoryRoot} ${term}`)
    : [];
  const extraResults = await Promise.all([
    ...variantQueries.map((variant) =>
      collect(variant, { skipOsmFallback: true }),
    ),
    ...categoryQueries.map((variant) =>
      collect(variant, { skipOsmFallback: true, itemsOnly: true }),
    ),
  ]);
  if (extraResults.length > 0) {
    merged = dedupe([...extraResults.flat(), ...merged]);
  }

  // 2GIS is the only source that usually knows a Latin spelling of a local
  // business. When it is unavailable (missing key, quota, outage) a query like
  // "Olzha" finds nothing in OSM, because the place is registered in Cyrillic
  // ("ОЛЖА"). Retry the transliterated brand there, one request at a time to
  // respect Nominatim's usage policy.
  if (merged.length === 0 && variantQueries.length > 0) {
    const cyrillicCity = /[а-яё]/i.test(cityScope)
      ? cityScope
      : transliterateToCyrillic(cityScope);
    for (const variant of variantQueries.slice(0, 2)) {
      const osmResults = await nominatimSearch(variant, {
        city: cyrillicCity,
        countryCode,
        limit,
        language: languageCode,
      });
      if (osmResults.length > 0) {
        merged = dedupe([...merged, ...osmResults]);
        break;
      }
    }
  }

  if (isBrandQuery && merged.length > 0) {
    const relatedTerms = [...new Set([
      normalizedRoot,
      ...normalizedRoot
        .split(' ')
        .filter((term) => term.length >= 3 && !CATEGORY_WORDS.has(term)),
      ...variants.map(normalize),
    ].filter(Boolean))];
    const related = merged.filter((item) => {
      const searchable = normalize(`${item.name} ${item.subtitle}`);
      return relatedTerms.some((term) => searchable.includes(term));
    });
    merged = related;
  }

  const typedResults = requestedTypes.size > 0
    ? merged.filter((item) => requestedTypes.has(item.type))
    : merged;
  const results = typedResults.slice(0, resultLimit);
  cacheSet(cacheKey, results);
  return results;
}

/**
 * Resolve a free-text place to a single best point. Used by geocoding when
 * 2GIS cannot resolve an address (countries, small towns, alternate spellings).
 */
export async function resolvePlace(address, city = '', language = 'az') {
  const results = await searchPlaces({ q: address, city, language, limit: 10 });
  if (results.length === 0) return null;
  const normalizedAddress = normalize(address);
  const exact = results.find((item) => normalize(item.name) === normalizedAddress);
  const cityOrCountry = results.find((item) => item.type === 'city' || item.type === 'country');
  return exact || cityOrCountry || results[0];
}

/** Exposed for diagnostics/tests. */
export const PLACE_GAZETTEER = { countries: COUNTRIES, cities: ALL_CITIES };
