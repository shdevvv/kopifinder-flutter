import { Router } from 'express';
import { z } from 'zod';
import { adminClient, requireAuth } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { dbFailure, isOwnedStorageObject, pagination, parse, sendData, sendPage } from '../utils/api';
import { config } from '../config/env';

const router = Router(); const uuid = z.string().uuid();
const reviewBody = z.object({ rating: z.number().int().min(1).max(5), text: z.string().trim().max(1000).nullable().optional(), photo_url: z.string().url().nullable().optional() }).strict();

router.get('/cafes/:id/reviews', async (req, res, next) => {
  try {
    const cafeId = parse(uuid, req.params.id); const { page, limit, from, to } = pagination(req.query); const client = req.supabase;
    const queryClient = client ?? (await import('../middleware/auth')).createSupabaseClient();
    const { data, error, count } = await queryClient.from('reviews').select('id,user_id,cafe_id,rating,text,photo_url,created_at,updated_at', { count: 'exact' }).eq('cafe_id', cafeId).order('created_at', { ascending: false }).range(from, to);
    if (error) throw dbFailure(error);
    const rows = data ?? []; const userIds = [...new Set(rows.map((x) => x.user_id))];
    // Read only explicitly public profile fields; never expose email or auth metadata.
    const { adminClient } = await import('../middleware/auth');
    const profiles = userIds.length ? await adminClient().from('users').select('id,full_name,username,avatar_url').in('id', userIds) : { data: [], error: null };
    if (profiles.error) throw dbFailure(profiles.error);
    const map = new Map((profiles.data ?? []).map((x: any) => [x.id, { ...x, name: x.full_name }]));
    sendPage(req, res, rows.map((x) => ({ ...x, reviewer: map.get(x.user_id) ?? null })), page, limit, (count ?? 0) > to + 1);
  } catch (e) { next(e); }
});

router.post('/cafes/:id/reviews', requireAuth, async (req, res, next) => {
  try {
    const cafeId = parse(uuid, req.params.id); const body = parse(reviewBody, req.body); const client = req.supabase!;
    if (!isOwnedStorageObject(body.photo_url, 'review-photos', req.user!.id, config.supabase.url)) throw new AppError('Foto review harus berasal dari folder Storage milik Anda.', 400, 'INVALID_PHOTO_PATH');
    const cafe = await client.from('cafes').select('id').eq('id', cafeId).eq('is_active', true).eq('verification_status', 'verified').maybeSingle();
    if (cafe.error) throw dbFailure(cafe.error); if (!cafe.data) throw new AppError('Kafe tidak ditemukan.', 404, 'NOT_FOUND');
    const existing = await client.from('reviews').select('id').eq('user_id', req.user!.id).eq('cafe_id', cafeId).maybeSingle();
    if (existing.error) throw dbFailure(existing.error); if (existing.data) throw new AppError('Anda sudah mengulas kafe ini.', 409, 'REVIEW_EXISTS');
    const { data, error } = await client.from('reviews').insert({ ...body, user_id: req.user!.id, cafe_id: cafeId }).select('id,cafe_id,rating,text,photo_url,created_at').single();
    if (error) throw dbFailure(error); sendData(req, res, data, 201);
  } catch (e) { next(e); }
});

router.delete('/reviews/:id', requireAuth, async (req, res, next) => {
  try {
    const id = parse(uuid, req.params.id); const isAdmin = (process.env.ADMIN_USER_IDS ?? '').split(',').map((x) => x.trim()).includes(req.user!.id); const client = isAdmin ? adminClient() : req.supabase!;
    const found = await client.from('reviews').select('id,user_id').eq('id', id).maybeSingle(); if (found.error) throw dbFailure(found.error);
    if (!found.data) throw new AppError('Ulasan tidak ditemukan.', 404, 'NOT_FOUND');
    if (found.data.user_id !== req.user!.id && !isAdmin) throw new AppError('Tidak diizinkan menghapus ulasan ini.', 403, 'FORBIDDEN');
    const { error } = await client.from('reviews').delete().eq('id', id); if (error) throw dbFailure(error); sendData(req, res, { deleted: true });
  } catch (e) { next(e); }
});

router.get('/saved-cafes', requireAuth, async (req, res, next) => {
  try {
    const { page, limit, from, to } = pagination(req.query);
    const { data, error, count } = await req.supabase!.from('saved_cafes').select('id,cafe_id,saved_at,cafes!inner(id,name,area,address,lat,lng,price_min,price_max,photos)', { count: 'exact' }).eq('user_id', req.user!.id).eq('cafes.is_active', true).eq('cafes.verification_status', 'verified').order('saved_at', { ascending: false }).range(from, to);
    if (error) throw dbFailure(error); sendPage(req, res, data ?? [], page, limit, (count ?? 0) > to + 1);
  } catch (e) { next(e); }
});

router.post('/saved-cafes', requireAuth, async (req, res, next) => {
  try {
    const { cafe_id: cafeId } = parse(z.object({ cafe_id: uuid }).strict(), req.body);
    const client = req.supabase!; const cafe = await client.from('cafes').select('id').eq('id', cafeId).eq('is_active', true).eq('verification_status', 'verified').maybeSingle();
    if (cafe.error) throw dbFailure(cafe.error); if (!cafe.data) throw new AppError('Kafe tidak ditemukan.', 404, 'NOT_FOUND');
    const { data, error } = await client.from('saved_cafes').upsert({ user_id: req.user!.id, cafe_id: cafeId }, { onConflict: 'user_id,cafe_id', ignoreDuplicates: true }).select('id,cafe_id,saved_at').maybeSingle();
    if (error) throw dbFailure(error); sendData(req, res, data ?? { cafe_id: cafeId, saved: true }, 201);
  } catch (e) { next(e); }
});

router.delete('/saved-cafes/:cafe_id', requireAuth, async (req, res, next) => {
  try {
    const cafeId = parse(uuid, req.params.cafe_id); const { error } = await req.supabase!.from('saved_cafes').delete().eq('user_id', req.user!.id).eq('cafe_id', cafeId);
    if (error) throw dbFailure(error); sendData(req, res, { cafe_id: cafeId, saved: false });
  } catch (e) { next(e); }
});

export default router;
