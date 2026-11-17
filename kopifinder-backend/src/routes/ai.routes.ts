import { Router } from 'express';
import { z } from 'zod';
import { config } from '../config/env';
import { requireAuth } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { dbFailure, pagination, parse, sendData, sendPage } from '../utils/api';

const router = Router();
const requestSchema = z.object({ purpose: z.enum(['Work', 'Study', 'Date', 'Hangout', 'Casual']), budget: z.enum(['<30k', '30k-60k', '>60k', '30000-60000']), details: z.string().trim().max(500).optional().default('') }).strict();
const hourly = new Map<string, number[]>();
router.use(requireAuth);

router.post('/recommend', async (req, res, next) => {
  try {
    const body = parse(requestSchema, req.body); const now = Date.now(); const key = req.user!.id;
    const recent = (hourly.get(key) ?? []).filter((t) => now - t < 3600000);
    if (recent.length >= config.aiRateLimitPerHour) throw new AppError('Batas rekomendasi AI per jam tercapai.', 429, 'RATE_LIMITED');
    recent.push(now); hourly.set(key, recent);
    if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY.startsWith('your-')) throw new AppError('Layanan rekomendasi belum dikonfigurasi.', 503, 'SERVICE_UNAVAILABLE');
    const low = body.budget === '<30k' ? 0 : body.budget === '>60k' ? 60001 : 30000;
    const high = body.budget === '<30k' ? 29999 : body.budget === '>60k' ? null : 60000;
    let query = req.supabase!.from('cafes').select('id,name,area,address,price_min,price_max,facilities,hours').eq('is_active', true).eq('verification_status', 'verified').order('name').limit(50);
    query = query.gte('price_min', low); if (high !== null) query = query.lte('price_min', high);
    const { data: candidates, error } = await query; if (error) throw dbFailure(error);
    if (!candidates?.length) { sendData(req, res, { recommendations: [], history_id: null, message: 'Tidak ada kafe terverifikasi pada rentang budget ini.' }); return; }
    const prompt = `Pilih maksimal 5 kafe dari daftar JSON ini untuk tujuan ${body.purpose}, budget ${body.budget}. Kebutuhan: ${body.details || 'tidak ada'}. Gunakan hanya data yang tersedia. Balas JSON murni {"recommendations":[{"cafe_id":"...","match_score":0,"reason":"..."}]}. Jangan membuat ID atau fakta baru. Kandidat: ${JSON.stringify(candidates)}`;
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(config.gemini.model)}:generateContent?key=${encodeURIComponent(process.env.GEMINI_API_KEY)}`;
    const response = await fetch(endpoint, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }], generationConfig: { responseMimeType: 'application/json', temperature: 0.2 } }), signal: AbortSignal.timeout(20000) });
    if (!response.ok) { console.error(`[${req.requestId}] Gemini returned HTTP ${response.status}`); throw new AppError('Layanan rekomendasi sedang tidak tersedia.', 502, 'AI_PROVIDER_ERROR'); }
    const payload = await response.json() as any; const raw = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
    let generated: any; try { generated = JSON.parse(raw); } catch { throw new AppError('Respons rekomendasi tidak dapat diproses.', 502, 'AI_INVALID_RESPONSE'); }
    const allowed = new Map(candidates.map((x) => [x.id, x]));
    const resultSchema = z.array(z.object({ cafe_id: z.string().uuid(), match_score: z.number().min(0).max(100), reason: z.string().min(1).max(500) })).max(5);
    const parsedRecommendations = resultSchema.safeParse(generated?.recommendations);
    if (!parsedRecommendations.success) throw new AppError('Respons rekomendasi tidak dapat diproses.', 502, 'AI_INVALID_RESPONSE');
    const recommendations = parsedRecommendations.data.filter((x) => allowed.has(x.cafe_id)).map((x) => ({ ...x, cafe_name: allowed.get(x.cafe_id)!.name }));
    const { data: history, error: historyError } = await req.supabase!.from('ai_recommendation_history').insert({ user_id: req.user!.id, purpose: body.purpose, budget: body.budget === '30000-60000' ? '30k-60k' : body.budget, details: body.details || null, result: { recommendations } }).select('id').single();
    if (historyError) throw dbFailure(historyError); sendData(req, res, { recommendations, history_id: history.id });
  } catch (e) { next(e); }
});

router.get('/history', async (req, res, next) => {
  try { const { page, limit, from, to } = pagination(req.query); const { data, error, count } = await req.supabase!.from('ai_recommendation_history').select('id,purpose,budget,details,result,created_at', { count: 'exact' }).eq('user_id', req.user!.id).order('created_at', { ascending: false }).range(from, to); if (error) throw dbFailure(error); sendPage(req, res, data ?? [], page, limit, (count ?? 0) > to + 1); }
  catch (e) { next(e); }
});
export default router;
