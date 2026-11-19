import { Router } from 'express';
import { z } from 'zod';
import { adminClient, createSupabaseClient, requireAuth } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { dbFailure, isOwnedStorageObject, pagination, parse, sendData, sendPage } from '../utils/api';
import { config } from '../config/env';

const router = Router(); const uuid = z.string().uuid();
const postBody = z.object({ cafe_id: uuid.nullable().optional(), caption: z.string().trim().min(1).max(500), photo_path: z.string().max(1000).nullable().optional() });
const commentBody = z.object({ text: z.string().trim().min(1).max(500), parent_id: uuid.nullable().optional() }).strict();

router.get('/posts', async (req, res, next) => {
  try {
    const { page, limit, from, to } = pagination(req.query); const client = req.supabase ?? createSupabaseClient();
    const { data, error, count } = await client.from('posts').select('id,user_id,cafe_id,caption,photo_url,likes_count,comments_count,created_at', { count: 'exact' }).order('created_at', { ascending: false }).range(from, to);
    if (error) throw dbFailure(error); const rows = data ?? []; const ids = rows.map((x) => x.id); const users = [...new Set(rows.map((x) => x.user_id))];
    const [likes, comments, profiles, myLikes] = await Promise.all([
      ids.length ? client.from('post_likes').select('post_id').in('post_id', ids) : Promise.resolve({ data: [], error: null }),
      ids.length ? client.from('comments').select('post_id').in('post_id', ids) : Promise.resolve({ data: [], error: null }),
      users.length ? adminClient().from('users').select('id,full_name,username,avatar_url').in('id', users) : Promise.resolve({ data: [], error: null }),
      req.user && ids.length ? client.from('post_likes').select('post_id').eq('user_id', req.user.id).in('post_id', ids) : Promise.resolve({ data: [], error: null }),
    ]);
    const err = likes.error ?? comments.error ?? profiles.error ?? myLikes.error; if (err) throw dbFailure(err);
    const groupCount = (items: any[], key: string) => items.reduce((m, x) => m.set(x[key], (m.get(x[key]) ?? 0) + 1), new Map());
    const lm = groupCount(likes.data ?? [], 'post_id'); const cm = groupCount(comments.data ?? [], 'post_id');
    const pm = new Map((profiles.data ?? []).map((x: any) => [x.id, { ...x, name: x.full_name }]));
    const mine = new Set((myLikes.data ?? []).map((x) => x.post_id));
    sendPage(req, res, rows.map((x) => ({ ...x, author: pm.get(x.user_id) ?? null, likes_count: (x.likes_count ?? 0) || (lm.get(x.id) ?? 0), comments_count: (x.comments_count ?? 0) || (cm.get(x.id) ?? 0), is_liked: mine.has(x.id) })), page, limit, (count ?? 0) > to + 1);
  } catch (e) { next(e); }
});

router.post('/posts', requireAuth, async (req, res, next) => {
  try {
    const body = parse(postBody, req.body); const client = req.supabase!;
    if (body.photo_path && !isOwnedStorageObject(body.photo_path, 'post-photos', req.user!.id, config.supabase.url)) {
      throw new AppError('Foto post harus berasal dari folder Storage milik Anda.', 400, 'INVALID_PHOTO_PATH');
    }
    if (body.cafe_id) {
      const cafe = await client.from('cafes').select('id').eq('id', body.cafe_id).eq('is_active', true).eq('verification_status', 'verified').maybeSingle();
      if (cafe.error) throw dbFailure(cafe.error);
      if (!cafe.data) throw new AppError('Kafe tidak ditemukan.', 404, 'NOT_FOUND');
    }
    const { data, error } = await client.from('posts').insert({
      user_id: req.user!.id,
      cafe_id: body.cafe_id ?? null,
      caption: body.caption,
      photo_url: body.photo_path ?? null,
    }).select('id,cafe_id,caption,photo_url,created_at').single();
    if (error) throw dbFailure(error);
    sendData(req, res, data, 201);
  } catch (e) { next(e); }
});

router.patch('/posts/:id', requireAuth, async (req, res, next) => {
  try {
    const id = parse(uuid, req.params.id);
    const body = z.object({ caption: z.string().trim().min(1).max(500) }).parse(req.body);
    const isAdmin = (process.env.ADMIN_USER_IDS ?? '').split(',').map((x) => x.trim()).includes(req.user!.id);
    const client = isAdmin ? adminClient() : req.supabase!;
    const found = await client.from('posts').select('id,user_id').eq('id', id).maybeSingle();
    if (found.error) throw dbFailure(found.error);
    if (!found.data) throw new AppError('Post tidak ditemukan.', 404, 'NOT_FOUND');
    if (found.data.user_id !== req.user!.id && !isAdmin) throw new AppError('Tidak diizinkan mengedit post ini.', 403, 'FORBIDDEN');
    const { data, error } = await client.from('posts').update({ caption: body.caption }).eq('id', id).select('id,caption').single();
    if (error) throw dbFailure(error);
    sendData(req, res, data);
  } catch (e) { next(e); }
});

router.delete('/posts/:id', requireAuth, async (req, res, next) => {
  try {
    const id = parse(uuid, req.params.id); const isAdmin = (process.env.ADMIN_USER_IDS ?? '').split(',').map((x) => x.trim()).includes(req.user!.id); const client = isAdmin ? adminClient() : req.supabase!; const found = await client.from('posts').select('id,user_id').eq('id', id).maybeSingle();
    if (found.error) throw dbFailure(found.error); if (!found.data) throw new AppError('Post tidak ditemukan.', 404, 'NOT_FOUND');
    if (found.data.user_id !== req.user!.id && !isAdmin) throw new AppError('Tidak diizinkan menghapus post ini.', 403, 'FORBIDDEN');
    const { error } = await client.from('posts').delete().eq('id', id); if (error) throw dbFailure(error); sendData(req, res, { deleted: true });
  } catch (e) { next(e); }
});

router.post('/posts/:id/like', requireAuth, async (req, res, next) => {
  try { const postId = parse(uuid, req.params.id); const { error } = await req.supabase!.from('post_likes').upsert({ post_id: postId, user_id: req.user!.id }, { onConflict: 'post_id,user_id', ignoreDuplicates: true }); if (error) throw dbFailure(error); sendData(req, res, { post_id: postId, liked: true }); }
  catch (e) { next(e); }
});
router.delete('/posts/:id/like', requireAuth, async (req, res, next) => {
  try { const postId = parse(uuid, req.params.id); const { error } = await req.supabase!.from('post_likes').delete().eq('post_id', postId).eq('user_id', req.user!.id); if (error) throw dbFailure(error); sendData(req, res, { post_id: postId, liked: false }); }
  catch (e) { next(e); }
});

router.get('/posts/:id/comments', async (req, res, next) => {
  try {
    const postId = parse(uuid, req.params.id); const { page, limit, from, to } = pagination(req.query); const client = req.supabase ?? createSupabaseClient();
    const { data, error, count } = await client.from('comments').select('id,post_id,user_id,parent_id,content,created_at', { count: 'exact' }).eq('post_id', postId).order('created_at', { ascending: true }).range(from, to);
    if (error) throw dbFailure(error); const rows = data ?? []; const ids = rows.map((x) => x.id); const users = [...new Set(rows.map((x) => x.user_id))];
    const [profiles, likes] = await Promise.all([
      users.length ? adminClient().from('users').select('id,full_name,username,avatar_url').in('id', users) : Promise.resolve({ data: [], error: null }),
      ids.length ? client.from('comment_likes').select('comment_id').in('comment_id', ids) : Promise.resolve({ data: [], error: null }),
    ]);
    if (profiles.error || likes.error) throw dbFailure(profiles.error ?? likes.error);
    const pm = new Map((profiles.data ?? []).map((x: any) => [x.id, { ...x, name: x.full_name }])); const lm = (likes.data ?? []).reduce((m: Map<string, number>, x) => m.set(x.comment_id, (m.get(x.comment_id) ?? 0) + 1), new Map());
    sendPage(req, res, rows.map((x) => ({ ...x, text: (x as any).content ?? (x as any).text ?? '', author: pm.get(x.user_id) ?? null, likes_count: lm.get(x.id) ?? 0 })), page, limit, (count ?? 0) > to + 1);
  } catch (e) { next(e); }
});

router.post('/posts/:id/comments', requireAuth, async (req, res, next) => {
  try {
    const postId = parse(uuid, req.params.id); const body = parse(commentBody, req.body); const client = req.supabase!;
    const post = await client.from('posts').select('id').eq('id', postId).maybeSingle(); if (post.error) throw dbFailure(post.error); if (!post.data) throw new AppError('Post tidak ditemukan.', 404, 'NOT_FOUND');
    if (body.parent_id) { const parent = await client.from('comments').select('id,parent_id').eq('id', body.parent_id).eq('post_id', postId).maybeSingle(); if (parent.error) throw dbFailure(parent.error); if (!parent.data || parent.data.parent_id) throw new AppError('parent_id harus komentar tingkat atas pada post yang sama.', 400, 'VALIDATION_ERROR'); }
    const { data, error } = await client.from('comments').insert({ post_id: postId, user_id: req.user!.id, content: body.text, parent_id: body.parent_id ?? null }).select('id,post_id,parent_id,content,created_at').single();
    if (error) throw dbFailure(error); sendData(req, res, { ...data, text: (data as any).content ?? '' }, 201);
  } catch (e) { next(e); }
});

router.delete('/comments/:id', requireAuth, async (req, res, next) => {
  try {
    const id = parse(uuid, req.params.id); const isAdmin = (process.env.ADMIN_USER_IDS ?? '').split(',').map((x) => x.trim()).includes(req.user!.id); const client = isAdmin ? adminClient() : req.supabase!; const found = await client.from('comments').select('id,user_id').eq('id', id).maybeSingle();
    if (found.error) throw dbFailure(found.error); if (!found.data) throw new AppError('Komentar tidak ditemukan.', 404, 'NOT_FOUND');
    if (found.data.user_id !== req.user!.id && !isAdmin) throw new AppError('Tidak diizinkan menghapus komentar ini.', 403, 'FORBIDDEN');
    const { error } = await client.from('comments').delete().eq('id', id); if (error) throw dbFailure(error); sendData(req, res, { deleted: true });
  } catch (e) { next(e); }
});

router.post('/comments/:id/like', requireAuth, async (req, res, next) => {
  try { const commentId = parse(uuid, req.params.id); const { error } = await req.supabase!.from('comment_likes').upsert({ comment_id: commentId, user_id: req.user!.id }, { onConflict: 'comment_id,user_id', ignoreDuplicates: true }); if (error) throw dbFailure(error); sendData(req, res, { comment_id: commentId, liked: true }); }
  catch (e) { next(e); }
});
router.delete('/comments/:id/like', requireAuth, async (req, res, next) => {
  try { const commentId = parse(uuid, req.params.id); const { error } = await req.supabase!.from('comment_likes').delete().eq('comment_id', commentId).eq('user_id', req.user!.id); if (error) throw dbFailure(error); sendData(req, res, { comment_id: commentId, liked: false }); }
  catch (e) { next(e); }
});

export default router;
