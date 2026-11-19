import { Router } from 'express';
import { z } from 'zod';
import { config } from '../config/env';
import { requireAuth } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { dbFailure, pagination, parse, sendData, sendPage } from '../utils/api';

const router = Router();

// Accept flexible casing from client; normalise internally
const purposeEnum = ['Work', 'Study', 'Aesthetic', 'Pet Friendly', 'Date', 'Hangout', 'Casual'] as const;
const budgetEnum = ['<15k', '15k-30k', '<30k', '30k-60k', '60k-80k', '>60k', '>80k', '30000-60000'] as const;

const requestSchema = z
  .object({
    purpose: z
      .string()
      .transform((v) => {
        // normalise: capitalise first letter of each word
        const normalised = v
          .split(' ')
          .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
          .join(' ');
        // map known aliases
        if (normalised === 'Pet friendly') return 'Pet Friendly';
        return normalised;
      })
      .pipe(z.enum(purposeEnum)),
    budget: z
      .string()
      .transform((v) => {
        // normalise budget strings sent by Flutter
        const lower = v.toLowerCase().replace(/\s/g, '').replace('rp', '').replace('k', 'k');
        if (lower.includes('15') && lower.includes('30')) return '15k-30k';
        if (lower.includes('30') && lower.includes('60')) return '30k-60k';
        if (lower.includes('60') && lower.includes('80')) return '60k-80k';
        if (lower.includes('80') || lower.startsWith('>80') || lower.startsWith('morethan80')) return '>80k';
        if (lower.startsWith('<15') || lower === 'under15k') return '<15k';
        if (lower.startsWith('<30')) return '<30k';
        if (lower.startsWith('>60')) return '>60k';
        return v as typeof budgetEnum[number];
      })
      .pipe(z.enum(budgetEnum)),
    preferences: z.string().trim().max(500).optional().default(''),
    details: z.string().trim().max(500).optional().default(''),
  })
  .strip();

const hourly = new Map<string, number[]>();
router.use(requireAuth);

router.post('/recommend', async (req, res, next) => {
  try {
    const body = parse(requestSchema, req.body);
    const now = Date.now();
    const key = req.user!.id;
    const recent = (hourly.get(key) ?? []).filter((t) => now - t < 3600000);
    if (recent.length >= config.aiRateLimitPerHour)
      throw new AppError('Batas rekomendasi AI per jam tercapai.', 429, 'RATE_LIMITED');
    recent.push(now);
    hourly.set(key, recent);

    if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY.startsWith('your-'))
      throw new AppError('Layanan rekomendasi belum dikonfigurasi.', 503, 'SERVICE_UNAVAILABLE');

    // Map budget to price range
    let low = 0;
    let high: number | null = null;
    switch (body.budget) {
      case '<15k':     low = 0;     high = 14999;  break;
      case '15k-30k':  low = 15000; high = 30000;  break;
      case '<30k':     low = 0;     high = 29999;  break;
      case '30k-60k':
      case '30000-60000': low = 30000; high = 60000; break;
      case '60k-80k':  low = 60000; high = 80000;  break;
      case '>60k':     low = 60001; high = null;   break;
      case '>80k':     low = 80001; high = null;   break;
    }

    // Map purpose to facility tags for filtering
    const purposeTag: Record<string, string | null> = {
      Work: 'wifi',
      Study: 'wifi',
      Aesthetic: null,
      'Pet Friendly': 'pet_friendly',
      Date: null,
      Hangout: null,
      Casual: null,
    };

    let query = req.supabase!
      .from('cafes')
      .select('id,name,area,address,price_min,price_max,facilities,hours,rating')
      .eq('is_active', true)
      .eq('verification_status', 'verified')
      .order('rating', { ascending: false })
      .limit(60);

    query = query.gte('price_min', low);
    if (high !== null) query = query.lte('price_min', high);

    const { data: candidates, error } = await query;
    if (error) throw dbFailure(error);

    if (!candidates?.length) {
      sendData(req, res, {
        recommendations: [],
        history_id: null,
        message: 'Tidak ada kafe terverifikasi pada rentang budget ini.',
      });
      return;
    }

    const userDetails = body.preferences || body.details || 'tidak ada preferensi khusus';
    const prompt = `Kamu adalah asisten rekomendasi kafe Jakarta. Pilih MAKSIMAL 5 kafe dari daftar JSON berikut yang PALING COCOK untuk:
- Tujuan: ${body.purpose}
- Budget per orang: ${body.budget}
- Preferensi tambahan: ${userDetails}

Pertimbangkan nama kafe, area, facilities, rating, dan harga saat memilih. WAJIB pilih kafe yang berbeda-beda dan relevan dengan tujuan.

Balas HANYA dengan JSON murni (tanpa komentar, tanpa markdown):
{"recommendations":[{"cafe_id":"<UUID dari data>","match_score":<0-100>,"reason":"<alasan 1-2 kalimat dalam Bahasa Indonesia>"}]}

Kandidat kafe (gunakan HANYA cafe_id UUID dari sini):
${JSON.stringify(candidates)}`;

    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(config.gemini.model)}:generateContent?key=${encodeURIComponent(process.env.GEMINI_API_KEY)}`;
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: 'application/json', temperature: 0.3 },
      }),
      signal: AbortSignal.timeout(25000),
    });

    if (!response.ok) {
      console.error(`[${req.requestId}] Gemini returned HTTP ${response.status}`);
      throw new AppError('Layanan rekomendasi sedang tidak tersedia.', 502, 'AI_PROVIDER_ERROR');
    }

    const payload = (await response.json()) as any;
    const raw = payload?.candidates?.[0]?.content?.parts?.[0]?.text;

    let generated: any;
    try {
      generated = JSON.parse(raw);
    } catch {
      throw new AppError('Respons rekomendasi tidak dapat diproses.', 502, 'AI_INVALID_RESPONSE');
    }

    const allowed = new Map(candidates.map((x) => [x.id, x]));
    const resultSchema = z
      .array(
        z.object({
          cafe_id: z.string().uuid(),
          match_score: z.number().min(0).max(100),
          reason: z.string().min(1).max(500),
        }),
      )
      .max(5);

    const parsedRecommendations = resultSchema.safeParse(generated?.recommendations);
    if (!parsedRecommendations.success)
      throw new AppError('Respons rekomendasi tidak dapat diproses.', 502, 'AI_INVALID_RESPONSE');

    const recommendations = parsedRecommendations.data
      .filter((x) => allowed.has(x.cafe_id))
      .map((x) => ({
        ...x,
        cafe_name: allowed.get(x.cafe_id)!.name,
        area: allowed.get(x.cafe_id)!.area,
      }));

    const { data: history, error: historyError } = await req.supabase!
      .from('ai_recommendation_history')
      .insert({
        user_id: req.user!.id,
        purpose: body.purpose,
        budget: body.budget === '30000-60000' ? '30k-60k' : body.budget,
        details: userDetails !== 'tidak ada preferensi khusus' ? userDetails : null,
        result: { recommendations },
      })
      .select('id')
      .single();

    if (historyError) throw dbFailure(historyError);
    sendData(req, res, { recommendations, history_id: history.id });
  } catch (e) {
    next(e);
  }
});

router.get('/history', async (req, res, next) => {
  try {
    const { page, limit, from, to } = pagination(req.query);
    const { data, error, count } = await req.supabase!
      .from('ai_recommendation_history')
      .select('id,purpose,budget,details,result,created_at', { count: 'exact' })
      .eq('user_id', req.user!.id)
      .order('created_at', { ascending: false })
      .range(from, to);
    if (error) throw dbFailure(error);
    sendPage(req, res, data ?? [], page, limit, (count ?? 0) > to + 1);
  } catch (e) {
    next(e);
  }
});

export default router;
