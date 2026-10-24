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

test('Aktau business search includes Kazakh Cyrillic spelling suggestions', async () => {
  const previousKey = process.env.TWOGIS_API_KEY;
  const previousAdapter = axios.defaults.adapter;
  const requestedQueries = [];
  process.env.TWOGIS_API_KEY = 'test-key';
  axios.defaults.adapter = async (config) => {
    const query = String(config.params?.q || '');
    requestedQueries.push({
      url: config.url,
      query,
      pageSize: config.params?.page_size,
      countrycodes: config.params?.countrycodes,
      acceptLanguage: config.params?.['accept-language'],
    });
    const isSuggestEndpoint = config.url.endsWith('/3.0/suggests');
    const isItemsEndpoint = config.url.endsWith('/3.0/items');
    const items = query.toLowerCase().includes('olzhay') && isSuggestEndpoint
      ? [{
          id: 'unrelated-prefix',
          name: 'Alligator Aktau',
          point: { lat: 43.651, lon: 51.161 },
          adm_div: [{ type: 'city', name: 'Aktau' }],
        }]
      : query.includes('олжай') && isItemsEndpoint
        ? [{
          id: 'olzhai-aktau',
          name: 'ОЛЖАЙ',
          address_name: '30 микрорайон, Aktau',
          point: { lat: 43.65, lon: 51.16 },
          adm_div: [{ type: 'city', name: 'Aktau' }],
        }]
        : [];
    return {
      data: { meta: { code: 200 }, result: { items } },
      status: 200,
      statusText: 'OK',
      headers: {},
      config,
    };
  };

  try {
    const results = await searchPlaces({ q: 'Olzhay', city: 'Aktau', language: 'kk' });
    assert.ok(requestedQueries.some(({ query }) => query === 'Aktau, олжай'));
    assert.ok(requestedQueries.some(({ url, query }) => url.endsWith('/3.0/items') && query === 'Aktau, олжай'));
    assert.ok(requestedQueries.some(({ pageSize }) => pageSize === 10));
    assert.ok(requestedQueries.some(({ countrycodes }) => countrycodes === 'kz'));
    assert.ok(requestedQueries.some(({ acceptLanguage }) => acceptLanguage === 'kk,ru,en'));
    assert.ok(!results.some(({ name }) => name === 'Alligator Aktau'));
    assert.ok(results.some(({ name, city }) => name === 'ОЛЖАЙ' && city === 'Aktau'));
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
