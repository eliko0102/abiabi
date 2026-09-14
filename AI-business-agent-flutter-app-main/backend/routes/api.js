import express from 'express';
import axios from 'axios';
import { analyze2GisLocation, suggest2GisAddress } from '../services/twogis.js';
import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

router.post('/chat', async (req, res) => {
  try {
    const { prompt, location_context: locationContext, language = 'az' } = req.body;

    if (!prompt) {
      return res.status(400).json({
        success: false,
        message: 'Prompt is required',
      });
    }

    const provider = process.env.AI_PROVIDER || 'gemini';
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      return res.status(500).json({
        success: false,
        message: 'AI API key not configured',
      });
    }

    const languageNames = { az: 'Azerbaijani', en: 'English', ru: 'Russian', kk: 'Kazakh' };
    const responseLanguage = languageNames[language] || languageNames.az;

    // AI Məsləhətçi üçün yenilənmiş Sistem Təlimatı (System Prompt)
    const systemInstructionText = `Sən yerli bizneslər, məkan analitikası və piyada trafikinin (insan axınının) artırılması üzrə ekspert Süni İntellekt Məsləhətçisisən (Tochka.ai Business Agent).
İstifadəçiyə ${responseLanguage} dilində cavab ver.

Sənin əsas vəzifələrin:
1. Ümumi, faydasız və ya nəzəri sözlər DEDİRMƏMƏK. Mütləq praktiki, icra oluna bilən (actionable) konkret biznes tövsiyələri vermək.
2. Mövcud və ya yeni bizneslər üçün piyada trafikini (insan axınını) artırmaq üzrə addım-addım strategiya təklif etmək (məsələn: 2GIS rəqəmsal reklam/pin, yaxın nəqliyyat dayanacaqlarından axını tutmaq, rəqiblərin zəif tərəflərindən istifadə, vizual giriş görünürlüyü).
3. Əgər daxil olan sorğuda canlı 2GIS məkan analitikası (locationContext) varsa, mütləq həmin ünvanı, rəqib sayını, parkinq və nəqliyyat göstəricilərini əsas gətirərək təhlil aparmaq.

Cavabın mütləq aşağıdakı strukturu izləməlidir:
- **Məkanın Cari Qiymətləndirilməsi:** Ünvan, əlçatanlıq balı və rəqabət vəziyyəti.
- **Piyada Trafikini (İnsan Axınını) Artırmaq Üçün 3 Konkret Addım:** Biznes sahibinin dərhal tətbiq edə biləcəyi praktiki həllər.
- **Risklərin Və Çatışmazlıqların Həlli:** Parkinq, görünürlük və ya rəqabət problemlərini necə aradan qaldırmalı.`;

    let contextText = '';
    if (locationContext && typeof locationContext === 'object') {
      contextText = `\n\nCANLI 2GIS MƏKAN ANALİTİKASI MƏLUMATLARI:\n${JSON.stringify(locationContext, null, 2)}`;
    }

    const fullPrompt = `${systemInstructionText}\n\nİSTİFADƏÇİ SORĞUSU: ${prompt}${contextText}`;

    if (provider === 'gemini') {
      try {
        const geminiResponse = await axios.post(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
          {
            contents: [{ parts: [{ text: fullPrompt }] }],
          },
          {
            params: { key: apiKey },
            headers: { 'Content-Type': 'application/json' },
          }
        );

        const aiMessage =
          geminiResponse.data?.candidates?.[0]?.content?.parts?.[0]?.text ||
          'Süni intellekt cavab yarada bilmədi.';

        return res.status(200).json({
          success: true,
          message: aiMessage,
          prompt: fullPrompt,
          provider: provider,
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

    res.status(200).json({
      success: true,
      message: 'Chat endpoint hazırdır',
      prompt: fullPrompt,
      provider: provider,
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
    const { q, city } = req.query;
    if (!q) {
      return res.status(400).json({ success: false, message: 'q parametri tələb olunur' });
    }
    const suggestions = await suggest2GisAddress(q, city);
    res.status(200).json({ success: true, suggestions });
  } catch (error) {
    console.error('Suggest error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/location-analysis', async (req, res) => {
  try {
    const { city, businessType, address, mapProvider } = req.body;
    const provider = (mapProvider || process.env.MAPS_PROVIDER || '2gis').toLowerCase();

    if (!city || !businessType) {
      return res.status(400).json({
        success: false,
        message: 'City və businessType tələb olunur',
      });
    }

    const analysis = await analyze2GisLocation({
      city,
      businessType,
      address: address || city,
      provider,
    });

    res.status(200).json({
      ...analysis,
      provider,
      city,
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