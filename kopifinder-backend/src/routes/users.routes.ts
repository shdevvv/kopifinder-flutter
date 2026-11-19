import { Router } from 'express';
import { z } from 'zod';
import { adminClient, createSupabaseClient, requireAuth } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { dbFailure, pagination, parse, sendData, sendPage } from '../utils/api';

const router = Router();
const profileSchema = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  full_name: z.string().trim().min(2).max(100).optional(),
  username: z.string().trim().toLowerCase().regex(/^[a-z0-9_]{3,30}$/).optional(),
  avatar_url: z.string().url().nullable().optional(),
  location: z.string().trim().max(100).nullable().optional(),
  bio: z.string().trim().max(500).nullable().optional(),
}).refine((x) => Object.keys(x).length > 0);

router.get('/check-username', async (req, res, next) => {
  try {
    const username = parse(z.string().trim().toLowerCase().regex(/^[a-z0-9_]{3,30}$/), req.query.username);
    const { data, error } = await (await import('../middleware/auth')).adminClient().from('users').select('id').eq('username', username).maybeSingle();
    if (error) throw dbFailure(error);
    sendData(req, res, { available: !data });
  } catch (e) { next(e); }
});

router.use(requireAuth);
router.get('/me', async (req, res, next) => {
  try {
    const { data, error } = await req.supabase!.from('users').select('id,username,full_name,avatar_url,role,created_at,updated_at').eq('id', req.user!.id).maybeSingle();
    if (error) throw dbFailure(error);
    if (!data) throw new AppError('Profil belum tersedia.', 404, 'NOT_FOUND');
    sendData(req, res, {
      id: data.id,
      name: data.full_name,
      full_name: data.full_name,
      username: data.username,
      avatar_url: data.avatar_url,
      location: 'Jakarta, Indonesia',
      role: data.role,
      created_at: data.created_at,
      updated_at: data.updated_at,
    });
  } catch (e) { next(e); }
});

router.patch('/me', async (req, res, next) => {
  try {
    const body = parse(profileSchema, req.body);
    const updates: Record<string, any> = {
      updated_at: new Date().toISOString(),
    };
    if (body.full_name || body.name) {
      updates.full_name = body.full_name ?? body.name;
    }
    if (body.username) {
      updates.username = body.username;
    }
    if (body.avatar_url !== undefined) {
      updates.avatar_url = body.avatar_url;
    }

    const { data, error } = await req.supabase!.from('users').update(updates).eq('id', req.user!.id).select('id,username,full_name,avatar_url,role,updated_at').single();
    if (error) throw dbFailure(error);
    sendData(req, res, {
      id: data.id,
      name: data.full_name,
      full_name: data.full_name,
      username: data.username,
      avatar_url: data.avatar_url,
      location: 'Jakarta, Indonesia',
      updated_at: data.updated_at,
    });
  } catch (e) { next(e); }
});

router.get('/me/stats', async (req, res, next) => {
  try {
    const client = req.supabase!; const userId = req.user!.id;
    const [reviews, saved, posts, comments] = await Promise.all([
      client.from('reviews').select('id', { count: 'exact', head: true }).eq('user_id', userId),
      client.from('saved_cafes').select('id', { count: 'exact', head: true }).eq('user_id', userId),
      client.from('posts').select('id', { count: 'exact', head: true }).eq('user_id', userId),
      client.from('comments').select('id', { count: 'exact', head: true }).eq('user_id', userId),
    ]);
    const error = reviews.error ?? saved.error ?? posts.error ?? comments.error;
    if (error) throw dbFailure(error);
    sendData(req, res, { reviews: reviews.count ?? 0, saved_cafes: saved.count ?? 0, posts: posts.count ?? 0, comments: comments.count ?? 0 });
  } catch (e) { next(e); }
});

router.get('/me/activity', async (req, res, next) => {
  try {
    const { page, limit, from, to } = pagination(req.query);
    const [reviews, posts] = await Promise.all([
      req.supabase!.from('reviews').select('id,cafe_id,rating,text,created_at').eq('user_id', req.user!.id).order('created_at', { ascending: false }).limit(100),
      req.supabase!.from('posts').select('id,cafe_id,caption,photo_url,created_at').eq('user_id', req.user!.id).order('created_at', { ascending: false }).limit(100),
    ]);
    if (reviews.error || posts.error) throw dbFailure(reviews.error ?? posts.error);
    const all = [...(reviews.data ?? []).map((x) => ({ ...x, type: 'review' })), ...(posts.data ?? []).map((x) => ({ ...x, type: 'post' }))].sort((a, b) => Date.parse(b.created_at) - Date.parse(a.created_at));
    sendPage(req, res, all.slice(from, to + 1), page, limit, all.length > to + 1);
  } catch (e) { next(e); }
});

router.post('/me/password-reset', async (req, res, next) => {
  try {
    const email = req.user!.email;
    if (!email) throw new AppError('Akun tidak memiliki email untuk proses pemulihan.', 400, 'INVALID_ACCOUNT');
    const { error } = await req.supabase!.auth.resetPasswordForEmail(email);
    if (error) throw new AppError('Permintaan reset password gagal.', 502, 'AUTH_PROVIDER_ERROR');
    sendData(req, res, { message: 'Jika email dapat menerima reset, instruksi akan dikirim.' }, 202);
  } catch (e) { next(e); }
});

router.delete('/me', async (req, res, next) => {
  try {
    const { password } = parse(z.object({ password: z.string().min(1).max(256) }).strict(), req.body);
    if (!req.user!.email) throw new AppError('Akun tidak memiliki email untuk konfirmasi.', 400, 'INVALID_ACCOUNT');
    const authCheck = await createSupabaseClient().auth.signInWithPassword({ email: req.user!.email, password });
    if (authCheck.error || authCheck.data.user?.id !== req.user!.id) throw new AppError('Konfirmasi akun gagal.', 401, 'REAUTHENTICATION_FAILED');
    const admin = adminClient();
    for (const bucket of ['avatars', 'review-photos', 'post-photos']) {
      const storage = admin.storage.from(bucket);
      for (let offset = 0; ; offset += 1000) {
        const { data, error } = await storage.list(req.user!.id, { limit: 1000, offset });
        if (error) throw new AppError('Berkas akun tidak dapat dibersihkan; akun belum dihapus.', 502, 'STORAGE_CLEANUP_FAILED');
        if (!data?.length) break;
        const paths = data.filter((x) => x.name && !x.id?.endsWith('/')).map((x) => `${req.user!.id}/${x.name}`);
        if (paths.length) {
          const { error: removeError } = await storage.remove(paths);
          if (removeError) throw new AppError('Berkas akun tidak dapat dibersihkan; akun belum dihapus.', 502, 'STORAGE_CLEANUP_FAILED');
        }
        if (data.length < 1000) break;
      }
    }
    const { error } = await admin.auth.admin.deleteUser(req.user!.id);
    if (error) throw new AppError('Akun tidak dapat dihapus saat ini.', 502, 'ACCOUNT_DELETION_FAILED');
    sendData(req, res, { deleted: true });
  } catch (e) { next(e); }
});

export default router;
