const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const router = express.Router();

function getProvider() {
  if (process.env.AI_PROVIDER) return process.env.AI_PROVIDER.toLowerCase();
  if (process.env.GROQ_API_KEY) return 'groq';
  return 'gemini';
}

async function generateWithGroq(prompt) {
  const apiKey = process.env.GROQ_API_KEY;
  const model = process.env.GROQ_MODEL || 'llama-3.1-8b-instant';
  if (!apiKey) throw new Error('GROQ_API_KEY is missing');

  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: [
        {
          role: 'system',
          content:
            'You are an AI assistant specialized in FBLA (Future Business Leaders of America). Provide helpful, accurate information and keep responses concise.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Groq API error ${response.status}: ${body}`);
  }

  const data = await response.json();
  return data?.choices?.[0]?.message?.content || 'No response from model.';
}

async function generateWithGemini(prompt) {
  const apiKey = process.env.GEMINI_API_KEY;
  const modelName = process.env.GEMINI_MODEL || 'gemini-1.5-flash';
  if (!apiKey) throw new Error('GEMINI_API_KEY is missing');

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({ model: modelName });
  const result = await model.generateContent(prompt);
  const response = await result.response;
  return response.text();
}

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

    const provider = getProvider();
    const text = provider === 'groq'
      ? await generateWithGroq(fullPrompt)
      : await generateWithGemini(fullPrompt);

    res.json({ text });
  } catch (error) {
    console.error('AI generation error:', error.message || error);
    res.status(500).json({ error: error.message || 'Failed to generate AI response' });
  }
});

module.exports = router;