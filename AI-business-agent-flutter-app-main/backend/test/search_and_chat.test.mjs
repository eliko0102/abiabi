import test from 'node:test';
import assert from 'node:assert/strict';
import axios from 'axios';
import express from 'express';
import apiRoutes, {
  buildChatPrompt,
  buildFollowUps,
  compactAnalysis,
} from '../routes/api.js';
import {
  normalize,
  searchPlaces,
  brandOnly,
  transliterateToCyrillic,
  transliterationVariants,
} from '../services/places.js';

test('normalize folds Azerbaijani and Kazakh spellings', () => {
  assert.equal(normalize('Qazaxıstan'), 'qazaxistan');
  assert.equal(normalize('Қазақстан'), 'казакстан');
  assert.equal(normalize('Almatı'), 'almati');
  assert.equal(normalize('Баку'), 'баку');
  assert.equal(normalize('  Gəncə  '), 'gence');
});

test('Latin business names fall back to their Cyrillic registration', () => {
  assert.equal(transliterateToCyrillic('Olzha'), 'олжа');
  assert.equal(transliterateToCyrillic('Olzha fitness club'), 'олжа фитнес клуб');
  assert.equal(transliterateToCyrillic('Aktau'), 'актау');
  assert.deepEqual(transliterationVariants('Olzhay'), ['олжай', 'олжа', 'олжаы']);
  assert.deepEqual(transliterationVariants('Olzhai'), ['олжай', 'олжа', 'олжаи']);
  assert.equal(brandOnly('Olzha fitness club'), 'Olzha');
  assert.equal(brandOnly('fitness club'), '');
});

test('Aktau business search includes relevant Olzha suggestions', async () => {
  const previousKey = process.env.TWOGIS_API_KEY;
  const previousAdapter = axios.defaults.adapter;
  const requestedQueries = [];
  process.env.TWOGIS_API_KEY = 'test-key';
  axios.defaults.adapter = async (config) => {
    const query = String(config.params?.q || '');
    const onItems = config.url.endsWith('/3.0/items');
    const byId = (id, name, lat) => ({
      id,
      name,
      address_name: `${id}, Aktau`,
      point: { lat, lon: 51.16 },
      adm_div: [{ type: 'city', name: 'Aktau' }],
    });
    requestedQueries.push({
      url: config.url,
      query,
      pageSize: config.params?.page_size,
      countrycodes: config.params?.countrycodes,
      acceptLanguage: config.params?.['accept-language'],
    });
    let items = [];
    if (query.includes('Olzha') && !onItems) {
      items = [byId('unrelated-prefix', 'Alligator Aktau', 43.651)];
    } else if (query.includes('Olzha market') && onItems) {
      items = [byId('olzha-market', 'Олжа, супермаркет', 43.652)];
    } else if (query.includes('Olzha магазин') && onItems) {
      items = [byId('olzha-fitness', 'Fitness Olzha Club', 43.653)];
    } else if (query.includes('Olzha рынок') && onItems) {
      items = [byId('olzha-build', 'Олжа строй, строительный рынок', 43.654)];
    } else if (query.includes('Olzha') && onItems) {
      items = [
        byId('olzha-komplex', 'Олжа, универсально-торговый комплекс', 43.655),
        byId('olzha-tc', 'ТЦ Олжа', 43.656),
        byId('olzha-bar', 'Олжа, бар', 43.657),
        byId('olzha-ceh', 'Олжа, цех натяжных потолков', 43.658),
        byId('olzha-mini', 'Олжа, мини-маркет', 43.659),
      ];
    } else if (query.includes('олжа') && onItems) {
      items = [byId('olzha-cyrillic', 'ОЛЖА', 43.66)];
    }
    return {
      data: { meta: { code: 200 }, result: { items } },
      status: 200,
      statusText: 'OK',
      headers: {},
      config,
    };
  };

  try {
    const results = await searchPlaces({ q: 'Olzha', city: 'Aktau', countryCode: 'KZ', language: 'kk' });
    assert.ok(requestedQueries.some(({ query }) => query === 'Aktau, олжа'));
    assert.ok(requestedQueries.some(({ query }) => query === 'Aktau, Olzha market'));
    assert.ok(requestedQueries.some(({ query }) => query === 'Aktau, Olzha магазин'));
    assert.ok(requestedQueries.some(({ query }) => query === 'Aktau, Olzha рынок'));
    assert.ok(requestedQueries.some(({ pageSize }) => pageSize === 10));
    assert.ok(requestedQueries.every(({ query }) => query.startsWith('Aktau, ')));
    assert.ok(!results.some(({ name }) => name === 'Alligator Aktau'));
    assert.ok(results.length >= 8);
    assert.equal(new Set(results.map((item) => item.id)).size, results.length);
    assert.ok(results.every(({ name }) => /olzh|олжа/i.test(name)));
  } finally {
    axios.defaults.adapter = previousAdapter;
    if (previousKey === undefined) delete process.env.TWOGIS_API_KEY;
    else process.env.TWOGIS_API_KEY = previousKey;
  }
});

test('Latin brand falls back to its Cyrillic OSM name without a 2GIS key', async () => {
  const previousKey = process.env.TWOGIS_API_KEY;
  const previousAdapter = axios.defaults.adapter;
  const osmQueries = [];
  delete process.env.TWOGIS_API_KEY;
  axios.defaults.adapter = async (config) => {
    const query = String(config.params?.q || '');
    const isOsm = String(config.url).includes('nominatim.openstreetmap.org');
    if (!isOsm) throw new Error(`unexpected request without a 2GIS key: ${config.url}`);
    osmQueries.push(query);
    const items = query.includes('олжа')
      ? [
          {
            lat: '43.6776391',
            lon: '51.1631739',
            name: 'ОЛЖА',
            display_name: 'ОЛЖА, 30 микрорайон, Актау, Казахстан',
            addresstype: 'shop',
            address: {
              suburb: '30 микрорайон',
              city: 'Актау',
              country: 'Казахстан',
              country_code: 'kz',
            },
            osm_type: 'way',
            osm_id: 384495765,
            boundingbox: ['43.6768775', '43.67843', '51.1621561', '51.1641778'],
          },
        ]
      : [];
    return { data: items, status: 200, statusText: 'OK', headers: {}, config };
  };

  try {
    const results = await searchPlaces({
      q: 'Olzha',
      city: 'Aktau',
      countryCode: 'KZ',
      language: 'ru',
    });
    assert.ok(osmQueries.includes('актау, олжа'));
    assert.equal(results.length, 1);
    assert.equal(results[0].name, 'ОЛЖА');
    assert.equal(results[0].source, 'nominatim');
  } finally {
    axios.defaults.adapter = previousAdapter;
    if (previousKey === undefined) delete process.env.TWOGIS_API_KEY;
    else process.env.TWOGIS_API_KEY = previousKey;
  }
});

test('search region can be selected independently or left worldwide', async () => {
  const previousKey = process.env.TWOGIS_API_KEY;
  const previousAdapter = axios.defaults.adapter;
  const requestedQueries = [];
  process.env.TWOGIS_API_KEY = 'test-key';
  axios.defaults.adapter = async (config) => {
    requestedQueries.push({
      query: String(config.params?.q || ''),
      countrycodes: config.params?.countrycodes,
    });
    return {
      data: { meta: { code: 200 }, result: { items: [] } },
      status: 200,
      statusText: 'OK',
      headers: {},
      config,
    };
  };

  try {
    await searchPlaces({
      q: 'Northstar',
      city: 'Baku',
      countryCode: 'AZ',
      language: 'az',
    });
    const selectedRegionQueries = [...requestedQueries];
    assert.ok(selectedRegionQueries.some(({ query }) => query === 'Baku, Northstar'));
    assert.ok(selectedRegionQueries.some(({ query }) => query === 'Baku, Northstar mağaza'));
    assert.ok(selectedRegionQueries.every(({ countrycodes }) => countrycodes !== 'kz'));

    requestedQueries.length = 0;
    await searchPlaces({ q: 'Northstar', language: 'en' });
    assert.ok(requestedQueries.some(({ query }) => query === 'Northstar'));
    assert.ok(requestedQueries.some(({ query }) => query === 'Northstar shop'));
    assert.ok(requestedQueries.every(({ query }) => !query.startsWith('Baku, ')));
    assert.ok(requestedQueries.every(({ countrycodes }) => !countrycodes));
  } finally {
    axios.defaults.adapter = previousAdapter;
    if (previousKey === undefined) delete process.env.TWOGIS_API_KEY;
    else process.env.TWOGIS_API_KEY = previousKey;
  }
});

test('country search returns the country and its places without any API key', async () => {
  const previousKey = process.env.TWOGIS_API_KEY;
  delete process.env.TWOGIS_API_KEY;
  try {
    const results = await searchPlaces({ q: 'Qazaxıstan', language: 'az', limit: 8 });
    assert.ok(results.length >= 2);
    assert.equal(results[0].type, 'country');
    assert.equal(results[0].name, 'Qazaxıstan');
    assert.ok(results[0].bbox, 'country result must carry bounds for the map');
    assert.ok(results.slice(1).every((item) => item.type === 'city'));
    assert.ok(results.some((item) => item.name === 'Almaty'));
    assert.ok(results.every((item) => Number.isFinite(item.lat) && Number.isFinite(item.lon)));
  } finally {
    if (previousKey) process.env.TWOGIS_API_KEY = previousKey;
  }
});

test('alternate city spellings resolve to one city instead of duplicates', async () => {
  const previousKey = process.env.TWOGIS_API_KEY;
  delete process.env.TWOGIS_API_KEY;
  try {
    const results = await searchPlaces({ q: 'Almatı', language: 'az', limit: 8 });
    assert.equal(results.length, 1);
    assert.equal(results[0].type, 'city');
    assert.equal(results[0].name, 'Almaty');
    assert.equal(results[0].country_code, 'KZ');
  } finally {
    if (previousKey) process.env.TWOGIS_API_KEY = previousKey;
  }
});

test('a country plus a city narrows the city list', async () => {
  const previousKey = process.env.TWOGIS_API_KEY;
  delete process.env.TWOGIS_API_KEY;
  try {
    const results = await searchPlaces({ q: 'Qazaxıstan Almatı', language: 'az', limit: 8 });
    assert.deepEqual(
      results.map((item) => item.name),
      ['Qazaxıstan', 'Almaty'],
    );
  } finally {
    if (previousKey) process.env.TWOGIS_API_KEY = previousKey;
  }
});

test('an explicit city query overrides the selected search region', async () => {
  const results = await searchPlaces({
    q: 'Aktau',
    city: 'Baku',
    countryCode: 'AZ',
    language: 'az',
  });
  assert.equal(results.length, 1);
  assert.equal(results[0].name, 'Aktau');
  assert.equal(results[0].country_code, 'KZ');
});

test('compactAnalysis keeps the chat context small and factual', () => {
  const analysis = {
    address: 'Aktau, 14 mkr',
    point: { lat: 43.6, lon: 51.1 },
    score: 72,
    competitors_500m: 6,
    competitors: Array.from({ length: 20 }, (_, index) => ({
      name: `Cafe ${index}`,
      distance_meters: 100 + index,
      rating: 4.5,
      review_count: 10,
      rubrics: ['Кафе', 'Кофе', 'Завтрак', 'Бизнес-ланч', 'Десерты'],
      schedule: { Mon: '9-22' },
    })),
    parking_1km: 0,
  };
  const compact = compactAnalysis(analysis);
  assert.equal(compact.competitors.length, 6);
  assert.equal(compact.competitors[0].rubrics.length, 4);
  assert.equal(compact.address, 'Aktau, 14 mkr');
  assert.equal(compact.score, 72);
});

test('chat prompt carries the attached analysis and grounding rules', () => {
  const analysis = {
    address: 'Aktau, 14 mkr',
    score: 72,
    competitors_500m: 6,
    parking_1km: 0,
    competitors: [{ name: 'Cafe A', distance_meters: 120 }],
  };
  const built = buildChatPrompt({
    prompt: 'Nə etməliyəm?',
    analysis,
    language: 'az',
    conversation: [
      { role: 'user', content: 'salam' },
      { role: 'assistant', content: 'salam, necə kömək edə bilərəm?' },
    ],
  });
  assert.equal(built.analysisUsed.address, 'Aktau, 14 mkr');
  assert.match(built.fullPrompt, /2GIS MƏKAN ANALİZİ/);
  assert.match(built.fullPrompt, /Cafe A/);
  assert.match(built.fullPrompt, /uydurma/);
  assert.match(built.fullPrompt, /ƏVVƏLKİ SÖHBƏT/);
  assert.match(built.fullPrompt, /Azerbaijani/);
});

test('follow-ups react to missing parking and high competition', () => {
  const followUps = buildFollowUps({ parking_1km: 0, competitors_500m: 7 }, 'az');
  assert.equal(followUps.length, 4);
  assert.ok(followUps[0].toLowerCase().includes('rəqabət'));
  assert.ok(followUps[1].toLowerCase().includes('parkinq'));
});

test('chat without any analysis is told to ask for an address', () => {
  const built = buildChatPrompt({ prompt: 'Salam', language: 'en' });
  assert.equal(built.analysisUsed, null);
  assert.match(built.fullPrompt, /2GIS analizi yoxdur/);
  assert.match(built.fullPrompt, /English/);
});

async function withServer(run) {
  const app = express();
  app.use(express.json());
  app.use('/api', apiRoutes);
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const port = server.address().port;
  try {
    await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('GET /api/suggest validates the query and returns typed results', async () => {
  await withServer(async (baseUrl) => {
    const tooShort = await fetch(`${baseUrl}/api/suggest?q=Q`);
    assert.equal(tooShort.status, 400);

    const response = await fetch(
      `${baseUrl}/api/suggest?q=${encodeURIComponent('Qazaxıstan')}&lang=az`,
    );
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.success, true);
    assert.equal(body.suggestions[0].type, 'country');
    assert.ok(body.suggestions[0].bbox);
  });
});

test('GET /api/suggest applies a user-selected country code', async () => {
  const previousKey = process.env.TWOGIS_API_KEY;
  const previousAdapter = axios.defaults.adapter;
  const requests = [];
  delete process.env.TWOGIS_API_KEY;
  axios.defaults.adapter = async (config) => {
    requests.push(config);
    return {
      data: [],
      status: 200,
      statusText: 'OK',
      headers: {},
      config,
    };
  };

  try {
    await withServer(async (baseUrl) => {
      const response = await fetch(
        `${baseUrl}/api/suggest?q=Redwood&city=Baku&countryCode=AZ&lang=az`,
      );
      assert.equal(response.status, 200);
      assert.ok(requests.some(({ params }) => params?.countrycodes === 'az'));
    });
  } finally {
    axios.defaults.adapter = previousAdapter;
    if (previousKey === undefined) delete process.env.TWOGIS_API_KEY;
    else process.env.TWOGIS_API_KEY = previousKey;
  }
});

test('GET /api/suggest can return only city and country choices', async () => {
  const previousKey = process.env.TWOGIS_API_KEY;
  const previousAdapter = axios.defaults.adapter;
  const requestedUrls = [];
  process.env.TWOGIS_API_KEY = 'test-key';
  axios.defaults.adapter = async (config) => {
    requestedUrls.push(config.url);
    return {
      data: [{
        place_id: 123,
        osm_type: 'relation',
        osm_id: 123,
        lat: '48.8566',
        lon: '2.3522',
        name: 'Paris',
        type: 'city',
        addresstype: 'city',
        address: { city: 'Paris', country: 'France', country_code: 'fr' },
        boundingbox: ['48.8', '48.9', '2.2', '2.4'],
      }],
      status: 200,
      statusText: 'OK',
      headers: {},
      config,
    };
  };

  try {
    await withServer(async (baseUrl) => {
      const response = await fetch(
        `${baseUrl}/api/suggest?q=Paris&types=city,country&lang=en`,
      );
      assert.equal(response.status, 200);
      const body = await response.json();
      assert.deepEqual(body.suggestions.map((item) => item.type), ['city']);
      assert.equal(body.suggestions[0].country_code, 'FR');
      assert.ok(requestedUrls.includes('https://nominatim.openstreetmap.org/search'));
    });
  } finally {
    axios.defaults.adapter = previousAdapter;
    if (previousKey === undefined) delete process.env.TWOGIS_API_KEY;
    else process.env.TWOGIS_API_KEY = previousKey;
  }
});

test('location picker searches outside the current GPS country', async () => {
  const previousKey = process.env.TWOGIS_API_KEY;
  const previousAdapter = axios.defaults.adapter;
  const nominatimRequests = [];
  process.env.TWOGIS_API_KEY = 'test-key';
  axios.defaults.adapter = async (config) => {
    if (config.url === 'https://nominatim.openstreetmap.org/search') {
      nominatimRequests.push(config);
      return {
        data: [{
          place_id: 456,
          osm_type: 'relation',
          osm_id: 456,
          lat: '48.8566',
          lon: '2.3522',
          name: 'Paris',
          type: 'city',
          addresstype: 'city',
          address: { city: 'Paris', country: 'France', country_code: 'fr' },
          boundingbox: ['48.8', '48.9', '2.2', '2.4'],
        }],
        status: 200,
        statusText: 'OK',
        headers: {},
        config,
      };
    }
    return {
      data: { meta: { code: 200 }, result: { items: [] } },
      status: 200,
      statusText: 'OK',
      headers: {},
      config,
    };
  };

  try {
    const results = await searchPlaces({
      q: 'Paris',
      city: 'Baku',
      countryCode: 'AZ',
      types: ['city', 'country'],
      language: 'en',
    });
    assert.equal(results[0].name, 'Paris');
    assert.equal(results[0].country_code, 'FR');
    assert.ok(nominatimRequests.length > 0);
    assert.ok(nominatimRequests.every(({ params }) => !params.countrycodes));
    assert.ok(nominatimRequests.every(({ params }) => params.q === 'Paris'));
  } finally {
    axios.defaults.adapter = previousAdapter;
    if (previousKey === undefined) delete process.env.TWOGIS_API_KEY;
    else process.env.TWOGIS_API_KEY = previousKey;
  }
});

test('POST /api/chat validates missing prompt and missing provider key', async () => {
  const previousKey = process.env.GEMINI_API_KEY;
  delete process.env.GEMINI_API_KEY;
  process.env.AI_PROVIDER = 'gemini';
  try {
    await withServer(async (baseUrl) => {
      const empty = await fetch(`${baseUrl}/api/chat`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({}),
      });
      assert.equal(empty.status, 400);

      const noKey = await fetch(`${baseUrl}/api/chat`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ prompt: 'Salam' }),
      });
      assert.equal(noKey.status, 500);
      assert.match((await noKey.json()).message, /key/i);
    });
  } finally {
    if (previousKey) process.env.GEMINI_API_KEY = previousKey;
  }
});

test('POST /api/location-analysis requires a place and a business type', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/location-analysis`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ city: 'Aktau' }),
    });
    assert.equal(response.status, 400);
  });
});
