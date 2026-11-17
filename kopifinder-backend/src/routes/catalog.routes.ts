import { Router } from 'express';
import { z } from 'zod';
import { createSupabaseClient, optionalAuth } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { dbFailure, pagination, parse, sendData, sendPage } from '../utils/api';

const router = Router();
const areas = ['Jaksel', 'Jakpus', 'Jakbar', 'Jaktim', 'Jakut'] as const;
const querySchema = z.object({ q: z.string().trim().max(100).optional(), area: z.enum(areas).optional(), sort: z.enum(['rating', 'distance', 'price']).optional(), lat: z.coerce.number().min(-90).max(90).optional(), lng: z.coerce.number().min(-180).max(180).optional() });
const uuid = z.string().uuid();
const distance = (a: any, lat: number, lng: number) => 6371000 * 2 * Math.asin(Math.sqrt(Math.sin(((a.lat - lat) * Math.PI / 180) / 2) ** 2 + Math.cos(lat * Math.PI / 180) * Math.cos(a.lat * Math.PI / 180) * Math.sin(((a.lng - lng) * Math.PI / 180) / 2) ** 2));
const clientFor = (req: any) => req.supabase ?? createSupabaseClient();

router.use(optionalAuth);
router.get('/places', async (req, res, next) => {
  try {
    const query = parse(querySchema.extend({ radius_m: z.coerce.number().int().min(100).max(50000).optional() }), req.query);
    const { page, limit, from, to } = pagination(req.query); const client = clientFor(req);
    let q = client.from('osm_places').select('id,osm_type,osm_id,name,area,address,lat,lng,phone,website,instagram,opening_hours,facilities,source_url,last_synced_at', { count: 'exact' }).eq('sync_status', 'active').order('name').range(from, to);
    if (query.q) q = q.ilike('name', `%${query.q}%`);
    if (query.area) q = q.eq('area', query.area);
    if (query.lat !== undefined && query.lng !== undefined && query.radius_m) {
      const dLat = query.radius_m / 111320; const dLng = query.radius_m / (111320 * Math.max(0.01, Math.cos(query.lat * Math.PI / 180)));
      q = q.gte('lat', query.lat - dLat).lte('lat', query.lat + dLat).gte('lng', query.lng - dLng).lte('lng', query.lng + dLng);
    }
    const { data, error, count } = await q; if (error) throw dbFailure(error);
    let rows = data ?? [];
    if (query.lat !== undefined && query.lng !== undefined && query.radius_m) rows = rows.filter((x: any) => distance(x, query.lat!, query.lng!) <= query.radius_m!);
    sendPage(req, res, rows, page, limit, (count ?? 0) > to + 1);
  } catch (e) { next(e); }
});

router.get('/places/:id', async (req, res, next) => {
  try {
    const id = parse(uuid, req.params.id);
    const { data, error } = await clientFor(req).from('osm_places').select('id,osm_type,osm_id,name,area,address,lat,lng,phone,website,instagram,opening_hours,facilities,source_url,last_synced_at,sync_status').eq('id', id).eq('sync_status', 'active').maybeSingle();
    if (error) throw dbFailure(error); if (!data) throw new AppError('Tempat tidak ditemukan.', 404, 'NOT_FOUND');
    sendData(req, res, { ...data, attribution: '© OpenStreetMap contributors, ODbL 1.0' });
  } catch (e) { next(e); }
});

router.get('/cafes', async (req, res, next) => {
  try {
    const query = parse(querySchema, req.query);
    if ((query.sort === 'distance' || query.lat !== undefined || query.lng !== undefined) && (query.lat === undefined || query.lng === undefined)) throw new AppError('lat dan lng wajib diisi bersama.', 400, 'VALIDATION_ERROR');
    const { page, limit, from, to } = pagination(req.query); const client = clientFor(req);
    let q = client.from('cafes').select('id,name,area,address,lat,lng,price_min,price_max,hours,phone,whatsapp,website,instagram,facilities,photos,created_at', { count: 'exact' }).eq('is_active', true).eq('verification_status', 'verified');
    if (query.q) q = q.ilike('name', `%${query.q}%`); if (query.area) q = q.eq('area', query.area);
    if (query.sort === 'price') q = q.not('price_min', 'is', null).order('price_min', { ascending: true, nullsFirst: false }); else q = q.order('name');
    const { data, error, count } = await q.range(from, to); if (error) throw dbFailure(error);
    let rows: any[] = data ?? [];
    if (query.sort === 'rating') {
      const ids = rows.map((x) => x.id);
      const reviews = ids.length ? await client.from('reviews').select('cafe_id,rating').in('cafe_id', ids) : { data: [], error: null };
      if (reviews.error) throw dbFailure(reviews.error);
      const stats = new Map<string, { sum: number; count: number }>();
      for (const r of reviews.data ?? []) { const x = stats.get(r.cafe_id) ?? { sum: 0, count: 0 }; x.sum += r.rating; x.count++; stats.set(r.cafe_id, x); }
      rows = rows.map((x) => ({ ...x, average_rating: stats.has(x.id) ? Number((stats.get(x.id)!.sum / stats.get(x.id)!.count).toFixed(2)) : null, review_count: stats.get(x.id)?.count ?? 0 })).sort((a, b) => (b.average_rating ?? -1) - (a.average_rating ?? -1));
    } else if (query.sort === 'distance' && query.lat !== undefined && query.lng !== undefined) rows = rows.sort((a, b) => distance(a, query.lat!, query.lng!) - distance(b, query.lat!, query.lng!)).map((x) => ({ ...x, distance_m: Math.round(distance(x, query.lat!, query.lng!)) }));
    sendPage(req, res, rows, page, limit, (count ?? 0) > to + 1);
  } catch (e) { next(e); }
});

router.get('/cafes/:id', async (req, res, next) => {
  try {
    const id = parse(uuid, req.params.id); const client = clientFor(req);
    const [cafe, menus, reviews, saved] = await Promise.all([
      client.from('cafes').select('id,name,area,address,lat,lng,price_min,price_max,hours,phone,whatsapp,website,instagram,facilities,photos').eq('id', id).eq('is_active', true).eq('verification_status', 'verified').maybeSingle(),
      client.from('menus').select('id,name,price,category').eq('cafe_id', id).order('name'),
      client.from('reviews').select('rating').eq('cafe_id', id),
      req.user ? client.from('saved_cafes').select('id').eq('user_id', req.user.id).eq('cafe_id', id).maybeSingle() : Promise.resolve({ data: null, error: null }),
    ]);
    if (cafe.error || menus.error || reviews.error || saved.error) throw dbFailure(cafe.error ?? menus.error ?? reviews.error ?? saved.error);
    if (!cafe.data) throw new AppError('Kafe tidak ditemukan.', 404, 'NOT_FOUND');
    const rs: { rating: number }[] = reviews.data ?? []; const average = rs.length ? rs.reduce((s: number, r: { rating: number }) => s + r.rating, 0) / rs.length : null;
    sendData(req, res, { ...cafe.data, menus: menus.data ?? [], review_summary: { average_rating: average === null ? null : Number(average.toFixed(2)), review_count: rs.length }, is_saved: Boolean(saved.data) });
  } catch (e) { next(e); }
});

export default router;
