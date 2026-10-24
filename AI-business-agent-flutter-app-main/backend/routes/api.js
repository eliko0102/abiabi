import express from 'express';
import axios from 'axios';
import { analyze2GisLocation } from '../services/twogis.js';
import { searchPlaces } from '../services/places.js';

const router = express.Router();

const LANGUAGE_NAMES = { az: 'Azerbaijani', en: 'English', ru: 'Russian', kk: 'Kazakh' };

/**
 * The chat never receives the whole 2GIS payload. A compact, stable snapshot
 * is enough for the model and keeps prompts small and cheap.
 */
export function compactAnalysis(analysis) {
  if (!analysis || typeof analysis !== 'object') return null;
  const list = (value, mapper, max = 6) =>
    Array.isArray(value) ? value.slice(0, max).map(mapper).filter(Boolean) : [];
  const point = analysis.point && typeof analysis.point === 'object'
    ? {
        lat: Number(analysis.point.lat) || null,
        lon: Number(analysis.point.lon) || null,
      }
    : null;
  return {
    address: analysis.address ?? null,
    point,
    updated_at: analysis.updated_at ?? null,
    business_query: analysis.business_query ?? null,
    score: analysis.score ?? null,
    accessibility_score: analysis.accessibility_score ?? null,
    competition_score: analysis.competition_score ?? null,
    pedestrian_traffic: analysis.pedestrian_traffic ?? null,
    pedestrian_traffic_estimate: analysis.pedestrian_traffic_estimate ?? null,
    competitors_500m: analysis.competitors_500m ?? null,
    competitors_1km: analysis.competitors_1km ?? null,
    nearest_competitor_meters: analysis.nearest_competitor_meters ?? null,
    transport_stops_1km: analysis.transport_stops_1km ?? null,
    parking_1km: analysis.parking_1km ?? null,
    nearby_places_1km: analysis.nearby_places_1km ?? null,
    competitors: list(analysis.competitors, (item) => ({
      name: item?.name ?? null,
      distance_meters: item?.distance_meters ?? null,
      rating: item?.rating ?? null,
      review_count: item?.review_count ?? null,
      rubrics: Array.isArray(item?.rubrics) ? item.rubrics.slice(0, 4) : [],
    })),
    transport_stops: list(analysis.transport_stops, (item) => ({
      name: item?.name ?? null,
      distance_meters: item?.distance_meters ?? null,
    })),
    parking: list(analysis.parking, (item) => ({
      name: item?.name ?? null,
      distance_meters: item?.distance_meters ?? null,
      is_paid: item?.is_paid ?? null,
      capacity: item?.capacity ?? null,
    })),
    nearby_places: list(analysis.nearby_places, (item) => ({
      name: item?.name ?? null,
      distance_meters: item?.distance_meters ?? null,
    })),
    insights: analysis.insights ?? null,
    analysis_quality: analysis.analysis_quality ?? null,
  };
}

/**
 * Gemini requires alternating user/model turns that start with the user.
 * The UI can produce consecutive assistant bubbles (welcome, analysis card),
 * so merge same-role turns and drop leading assistant messages.
 */
export function sanitizeHistory(conversation) {
  const raw = (Array.isArray(conversation) ? conversation : [])
    .filter((item) => item && ['user', 'assistant'].includes(item.role))
    .slice(-10)
    .map((item) => ({
      role: item.role,
      text: String(item.content ?? item.text ?? '').slice(0, 1500).trim(),
    }))
    .filter((item) => item.text);
  while (raw.length > 0 && raw[0].role === 'assistant') raw.shift();
  const merged = [];
  for (const turn of raw) {
    const last = merged[merged.length - 1];
    if (last && last.role === turn.role) {
      last.text = `${last.text}\n${turn.text}`.slice(0, 3000);
    } else {
      merged.push({ ...turn });
    }
  }
  return merged.slice(-8);
}

const ANALYSIS_RULES = `Əgər mesajda 2GIS MƏKAN ANALİZİ (analysis) varsa:
- Cavabı YALNIZ həmin rəqəmlərə əsaslandır (bal, rəqib sayı, məsafələr, parkinq, dayanacaq, rəylər).
- Rəqəm verilməyibsə "bu göstərici 2GIS məlumatında yoxdur" yaz; rəqəm uydurma.
- Rəqibləri adları və məsafələri ilə konkret qeyd et.
- Cavabı mütləq bu üç başlıqla qur:
  1) **Məkanın qiymətləndirilməsi** — ünvan, ümumi bal, əlçatanlıq və rəqabət.
  2) **İnsan axınını artırmaq üçün 3 addım** — hər addım 1-2 cümlə, icra edilə bilən.
  3) **Risklər və həlli** — parkinq, görünürlük, rəqabət üzrə konkret həll.
- Sonda 1 cümləlik "növbəti addım" yaz.`;

/**
 * Builds the final prompt. Exported so the contract can be tested without
 * calling the AI provider.
 */
export function buildChatPrompt({ prompt, analysis, language = 'az', conversation = [] }) {
  const languageName = LANGUAGE_NAMES[language] || LANGUAGE_NAMES.az;
  const compact = compactAnalysis(analysis);
  const history = sanitizeHistory(conversation).map(
    (item) => `${item.role === 'user' ? 'İSTİFADƏÇİ' : 'KÖMƏKÇİ'}: ${item.text}`,
  );
  const system = `Sən yerli bizneslər, məkan analitikası və piyada trafikinin artırılması üzrə ekspert AI məsləhətçisisən (Tochka.ai Business Agent).
İstifadəçiyə ${languageName} dilində cavab ver.
Ümumi və nəzəri məsləhət vermə; hər tövsiyə konkret və icra oluna bilən olsun.
2GIS rəqəmsal görünürlüyü, yaxın nəqliyyat dayanacaqları, yaxın "maqnit" obyektlər, rəqiblərin zəif tərəfləri və giriş görünürlüyü barədə praktiki taktikalar ver.

${compact ? ANALYSIS_RULES : 'Hazırda 2GIS analizi yoxdur. Əgər sual konkret ünvanla bağlıdırsa, istifadəçidən ünvanı çatda göndərməsini xahiş et.'}${
    compact
      ? `\n\n2GIS MƏKAN ANALİZİ (yeganə həqiqət mənbəyi):\n${JSON.stringify(compact)}`
      : ''
  }${history.length ? `\n\nƏVVƏLKİ SÖHBƏT:\n${history.join('\n')}` : ''}`;

  const request = prompt?.trim() || 'Bu məkan analizini izah et və insan axınını artırmaq üçün plan ver.';
  return {
    system,
    prompt: request,
    fullPrompt: `${system}\n\nİSTİFADƏÇİ SORĞUSU: ${request}`,
    analysisUsed: compact,
  };
}

/** Deterministic follow-up chips so the UI always has next steps. */
export function buildFollowUps(analysis, language = 'az') {
  const base = {
    az: [
      'Rəqibləri necə üstələyə bilərəm?',
      'İnsan axınını artırmaq üçün 7 günlük plan ver',
      'Bu məkan üçün əsas risklər nələrdir?',
      '2GIS-də görünürlüyü necə artırım?',
    ],
    en: [
      'How can I outperform these competitors?',
      'Give me a 7-day plan to increase foot traffic',
      'What are the main risks of this location?',
      'How do I improve visibility on 2GIS?',
    ],
    ru: [
      'Как обойти этих конкурентов?',
      'Дай план на 7 дней для роста трафика',
      'Какие главные риски у этой локации?',
      'Как повысить видимость в 2GIS?',
    ],
    kk: [
      'Бәсекелестерден қалай озуға болады?',
      'Трафикті арттыру үшін 7 күндік жоспар бер',
      'Бұл орынның негізгі тәуекелдері қандай?',
      '2GIS-те көрінуді қалай арттырамын?',
    ],
  };
  const items = [...(base[language] || base.az)];
  if (analysis && Number(analysis.parking_1km) === 0) {
    items.unshift(
      language === 'ru'
        ? 'Парковки рядом нет — что делать?'
        : language === 'en'
          ? 'There is no parking nearby — what should I do?'
          : language === 'kk'
            ? 'Жақын жерде тұрақ жоқ — не істеу керек?'
            : 'Yaxınlıqda parkinq yoxdur — nə etməliyəm?',
    );
  }
  if (analysis && Number(analysis.competitors_500m) >= 5) {
    items.unshift(
      language === 'ru'
        ? 'Конкуренция высокая — какое позиционирование выбрать?'
        : language === 'en'
          ? 'Competition is high — how should I position?'
          : language === 'kk'
            ? 'Бәсеке жоғары — қалай позициялану керек?'
            : 'Rəqabət yüksəkdir — necə fərqlənməliyəm?',
    );
  }
  return [...new Set(items)].slice(0, 4);
}

router.post('/chat', async (req, res) => {
  try {
    const {
      prompt,
      language = 'az',
      conversation = [],
      analysis_context: analysisContext,
      location_context: locationContext,
      analysis: analysisPayload,
    } = req.body || {};
    const analysis = analysisContext || locationContext || analysisPayload || null;

    if (!prompt && !analysis) {
      return res.status(400).json({
        success: false,
        message: 'Prompt və ya analysis_context tələb olunur',
      });
    }

    const provider = (process.env.AI_PROVIDER || 'gemini').toLowerCase();
    const apiKey = process.env.GEMINI_API_KEY;

    if (provider === 'gemini' && !apiKey) {
      return res.status(500).json({
        success: false,
        message: 'AI API key not configured',
      });
    }

    const built = buildChatPrompt({
      prompt,
      analysis,
      language,
      conversation,
    });
    const followUps = buildFollowUps(built.analysisUsed, language);

    if (provider === 'gemini') {
      try {
        const history = sanitizeHistory(conversation).map((item) => ({
          role: item.role === 'user' ? 'user' : 'model',
          parts: [{ text: item.text }],
        }));
        const geminiResponse = await axios.post(
          `https://generativelanguage.googleapis.com/v1beta/models/${
            process.env.GEMINI_MODEL || 'gemini-2.5-flash'
          }:generateContent`,
          {
            contents: [...history, { role: 'user', parts: [{ text: built.fullPrompt }] }],
            generationConfig: { temperature: 0.4, maxOutputTokens: 1600 },
          },
          {
            params: { key: apiKey },
            headers: { 'Content-Type': 'application/json' },
            timeout: 45000,
          },
        );

        const aiMessage =
          geminiResponse.data?.candidates?.[0]?.content?.parts
            ?.map((part) => part?.text)
            .filter(Boolean)
            .join('\n') || 'Süni intellekt cavab yarada bilmədi.';

        return res.status(200).json({
          success: true,
          message: aiMessage,
          provider,
          model: process.env.GEMINI_MODEL || 'gemini-2.5-flash',
          analysis_used: Boolean(built.analysisUsed),
          analysis_address: built.analysisUsed?.address ?? null,
          follow_ups: followUps,
          userId: req.user?.id || null,
        });
      } catch (apiError) {
        console.error('Gemini API Error:', apiError.response?.data || apiError.message);
        return res.status(500).json({
          success: false,
          message: 'Gemini API sorğusunda xəta baş verdi',
          error: apiError.response?.data?.error?.message || apiError.message,
        });
      }
    }

    // Other providers are configured elsewhere; answer deterministically so the
    // client contract (message + follow_ups) never breaks.
    return res.status(200).json({
      success: true,
      message: `AI provayderi "${provider}" üçün cavab hazırdır.`,
      provider,
      analysis_used: Boolean(built.analysisUsed),
      analysis_address: built.analysisUsed?.address ?? null,
      follow_ups: followUps,
      userId: req.user?.id || null,
    });
  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({
      success: false,
      message: 'Çat emal edilərkən xəta baş verdi',
      error: error.message,
    });
  }
});

router.get('/suggest', async (req, res) => {
  try {
    const { q, city, countryCode, types, lang, limit } = req.query;
    if (!q || String(q).trim().length < 2) {
      return res.status(400).json({
        success: false,
        message: 'q parametri ən azı 2 simvol olmalıdır',
      });
    }
    const suggestions = await searchPlaces({
      q: String(q),
      city: city ? String(city) : '',
      countryCode: countryCode ? String(countryCode) : '',
      types: types ? String(types).split(',') : [],
      language: lang ? String(lang) : 'az',
      limit: limit ? Number(limit) : 12,
    });
    res.status(200).json({ success: true, suggestions });
  } catch (error) {
    console.error('Suggest error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/location-analysis', async (req, res) => {
  try {
    const { city, businessType, address, mapProvider, point } = req.body || {};
    const provider = (mapProvider || process.env.MAPS_PROVIDER || '2gis').toLowerCase();

    if ((!city && !address) || !businessType) {
      return res.status(400).json({
        success: false,
        message: 'Ünvan/şəhər və businessType tələb olunur',
      });
    }

    const analysis = await analyze2GisLocation({
      city: city || address,
      businessType,
      address: address || city,
      provider,
      point: point && typeof point === 'object' ? point : null,
    });

    res.status(200).json({
      ...analysis,
      provider,
      city: city || address,
      businessType,
      userId: req.user?.id || null,
    });
  } catch (error) {
    console.error('Location analysis error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Analiz zamanı xəta baş verdi',
      error: error.message,
    });
  }
});

export default router;
