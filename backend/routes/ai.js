const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const router = express.Router();

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

// POST /ai/generate
router.post('/generate', async (req, res) => {
  try {
    const { prompt } = req.body;

    if (!prompt) {
      return res.status(400).json({ error: 'Prompt is required' });
    }

    // Create a system prompt to make the AI knowledgeable about FBLA
    const systemPrompt = `You are an AI assistant specialized in FBLA (Future Business Leaders of America). 
    Provide helpful, accurate information about FBLA events, competitions, membership, leadership, and business education.
    Keep responses informative but concise. If the question is not related to FBLA, politely redirect to FBLA topics.
    Always encourage learning and participation in FBLA activities.`;

    const fullPrompt = `${systemPrompt}\n\nUser question: ${prompt}`;

    const result = await model.generateContent(fullPrompt);
    const response = await result.response;
    const text = response.text();

    res.json({ text });
  } catch (error) {
    console.error('AI generation error:', error);
    res.status(500).json({ error: 'Failed to generate AI response' });
  }
});

module.exports = router;