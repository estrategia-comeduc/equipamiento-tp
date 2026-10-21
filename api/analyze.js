// Vercel Serverless Function — Anthropic API proxy
// Deployed at: /api/analyze (POST)
// Called by index.html when the user clicks "Analizar con IA"

export const config = { runtime: 'edge' };

export default async function handler(req) {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return new Response(JSON.stringify({ error: 'ANTHROPIC_API_KEY no configurada' }), {
      status: 500, headers: { 'Content-Type': 'application/json' }
    });
  }

  let body;
  try { body = await req.json(); }
  catch { return new Response('Bad Request', { status: 400 }); }

  const { prompt } = body;
  if (!prompt || typeof prompt !== 'string') {
    return new Response(JSON.stringify({ error: 'Falta el campo "prompt"' }), {
      status: 400, headers: { 'Content-Type': 'application/json' }
    });
  }

  const anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'anthropic-version': '2023-06-01',
      'x-api-key': apiKey,
    },
    body: JSON.stringify({
      model: 'claude-3-5-haiku-20241022',
      max_tokens: 2048,
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  if (!anthropicRes.ok) {
    const text = await anthropicRes.text();
    return new Response(JSON.stringify({ error: 'Error Anthropic API', detail: text }), {
      status: anthropicRes.status, headers: { 'Content-Type': 'application/json' }
    });
  }

  const data = await anthropicRes.json();
  // El front-end usa `result.text` (igual que `sample.json()` devuelve el valor directo)
  const text = data?.content?.[0]?.text ?? '';
  return new Response(JSON.stringify({ text }), {
    status: 200, headers: { 'Content-Type': 'application/json' }
  });
}
