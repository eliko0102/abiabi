import express from 'express';
import axios from 'axios';
import { analyze2GisLocation } from '../services/twogis.js';
import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

// Chat endpoint supports guests; other analysis endpoints remain protected.
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
    const contextText = locationContext
      ? `\n\nCurrent live 2GIS location analysis:\n${JSON.stringify(locationContext)}`
      : '';
    const groundedPrompt = `Respond in ${responseLanguage}. Keep the answer concise and useful.\n\n${prompt}${contextText}`;

    // Call Gemini API
    if (provider === 'gemini') {
      try {
        const geminiResponse = await axios.post(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent',
          {
            contents: [
              {
                parts: [
                  {
                    text: groundedPrompt,
                  },
                ],
              },
            ],
          },
          {
            params: {
              key: apiKey,
            },
            headers: {
              'Content-Type': 'application/json',
            },
          }
        );

        const aiMessage =
          geminiResponse.data?.candidates?.[0]?.content?.parts?.[0]?.text ||
          'AI could not generate response';

        return res.status(200).json({
          success: true,
          message: aiMessage,
          prompt: groundedPrompt,
          provider: provider,
          userId: req.user?.id || null,
        });
      } catch (apiError) {
        console.error('Gemini API Error:', apiError.response?.data || apiError.message);
        return res.status(500).json({
          success: false,
          message: 'Error calling Gemini API',
          error: apiError.response?.data?.error?.message || apiError.message,
        });
      }
    }

    // Fallback response
    const response = {
      success: true,
      message: 'Chat endpoint is ready',
      prompt: groundedPrompt,
      provider: provider,
      userId: req.user?.id || null,
    };

    res.status(200).json(response);
  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({
      success: false,
      message: 'Error processing chat',
      error: error.message,
    });
  }
});

// Location analysis endpoint. It is intentionally usable by guest chat so the
// user can discover a location before deciding to create an account.
router.post('/location-analysis', async (req, res) => {
  try {
    const { city, businessType, address } = req.body;

    if (!city || !businessType) {
      return res.status(400).json({
        success: false,
        message: 'City and businessType are required',
      });
    }

    const analysis = await analyze2GisLocation({
      city,
      businessType,
      address: address || city,
    });

    res.status(200).json({
      ...analysis,
      city,
      businessType,
      userId: req.user?.id || null,
    });
  } catch (error) {
    console.error('Location analysis error:', error);
    res.status(500).json({
      success: false,
      message: '2GIS location analysis failed',
      error: error.message,
    });
  }
});

// ROI calculation endpoint
router.post('/roi', verifyToken, async (req, res) => {
  try {
    const { rent, averageTicket, margin = 0.35 } = req.body;

    if (!rent || !averageTicket) {
      return res.status(400).json({
        success: false,
        message: 'Rent and averageTicket are required',
      });
    }

    // Simple ROI calculation
    const monthlyRevenue = averageTicket * 30; // Assuming 30 transactions per day
    const monthlyProfit = monthlyRevenue * margin - rent;
    const roi = (monthlyProfit / rent) * 100;

    const response = {
      success: true,
      message: 'ROI calculated successfully',
      monthlyRevenue,
      monthlyProfit,
      roi: roi.toFixed(2),
      userId: req.user.id,
    };

    res.status(200).json(response);
  } catch (error) {
    console.error('ROI calculation error:', error);
    res.status(500).json({
      success: false,
      message: 'Error calculating ROI',
      error: error.message,
    });
  }
});

export default router;
