import { Router } from 'express';
import { z } from 'zod';
import { adminClient } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { parse, sendData } from '../utils/api';

const router = Router();

const registerSchema = z.object({
  email: z.string().trim().email(),
  password: z.string().min(6),
  full_name: z.string().trim().min(2).max(100),
  username: z.string().trim().toLowerCase().regex(/^[a-z0-9_]{3,30}$/),
});

router.post('/register', async (req, res, next) => {
  try {
    const { email, password, full_name, username } = parse(registerSchema, req.body);
    const admin = adminClient();

    // 1. Cek apakah username sudah dipakai di public.users
    const { data: existingUser } = await admin
      .from('users')
      .select('id')
      .eq('username', username)
      .maybeSingle();

    if (existingUser) {
      throw new AppError('Username sudah digunakan, silakan pilih username lain.', 409, 'USERNAME_TAKEN');
    }

    // 2. Buat user di auth.users dengan email_confirm: true agar bisa langsung login
    const { data: authData, error: authError } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name,
        username,
        name: full_name,
      },
    });

    if (authError) {
      if (authError.message.toLowerCase().includes('already') || authError.message.toLowerCase().includes('registered')) {
        throw new AppError('Email sudah terdaftar. Silakan login dengan email ini.', 409, 'EMAIL_EXISTS');
      }
      throw new AppError(authError.message, 400, 'AUTH_ERROR');
    }

    const userId = authData.user.id;
    const now = new Date().toISOString();

    // 3. Masukkan atau sinkronkan data ke public.users
    const { error: dbError } = await admin.from('users').upsert(
      {
        id: userId,
        full_name,
        username,
        avatar_url: null,
        role: 'user',
        created_at: now,
        updated_at: now,
      },
      { onConflict: 'id' }
    );

    if (dbError) {
      console.error('Failed to insert to public.users:', dbError);
    }

    sendData(req, res, {
      message: 'Registrasi berhasil',
      user: {
        id: userId,
        email: authData.user.email,
        full_name,
        username,
      },
    }, 201);
  } catch (e) {
    next(e);
  }
});

// Endpoint untuk sinkronisasi profil user jika belum ada di tabel users
router.post('/sync', async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new AppError('Autentikasi diperlukan', 401, 'UNAUTHORIZED');
    }
    const token = authHeader.substring(7);
    const admin = adminClient();
    const { data: userData, error: userError } = await admin.auth.getUser(token);
    if (userError || !userData?.user) {
      throw new AppError('Sesi tidak valid', 401, 'UNAUTHORIZED');
    }

    const user = userData.user;
    const meta = user.user_metadata || {};
    const fullName = meta.full_name || meta.name || user.email?.split('@')[0] || 'User';
    const rawUsername = (meta.username || user.email?.split('@')[0] || 'user').toLowerCase().replace(/[^a-z0-9_]/g, '');
    const username = rawUsername.length >= 3 ? rawUsername : `user_${user.id.slice(0, 5)}`;

    const { data: dbUser } = await admin.from('users').select('*').eq('id', user.id).maybeSingle();

    if (!dbUser) {
      const now = new Date().toISOString();
      await admin.from('users').insert({
        id: user.id,
        full_name: fullName,
        username,
        avatar_url: meta.avatar_url || null,
        role: 'user',
        created_at: now,
        updated_at: now,
      });
    }

    sendData(req, res, {
      id: user.id,
      email: user.email,
      full_name: dbUser?.full_name || fullName,
      username: dbUser?.username || username,
    });
  } catch (e) {
    next(e);
  }
});

export default router;
