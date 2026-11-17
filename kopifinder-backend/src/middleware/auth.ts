import { createClient, SupabaseClient, User } from '@supabase/supabase-js';
import { NextFunction, Request, Response } from 'express';
import { config } from '../config/env';
import { AppError } from './errorHandler';

export const createSupabaseClient = (accessToken?: string): SupabaseClient => {
  if (!config.supabase.url || !config.supabase.anonKey) {
    throw new AppError('Backend authentication service is not configured.', 503, 'SERVICE_UNAVAILABLE');
  }
  return createClient(config.supabase.url, config.supabase.anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    ...(accessToken ? { global: { headers: { Authorization: `Bearer ${accessToken}` } } } : {}),
  });
};

export const optionalAuth = async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
  const header = req.header('authorization');
  if (!header) return next();
  const match = /^Bearer\s+(.+)$/i.exec(header);
  if (!match) return next(new AppError('Invalid authorization header.', 401, 'UNAUTHORIZED'));
  try {
    const client = createSupabaseClient(match[1]);
    const { data, error } = await client.auth.getUser(match[1]);
    if (error || !data.user) return next(new AppError('A valid access token is required.', 401, 'UNAUTHORIZED'));
    req.user = data.user;
    req.supabase = client;
    next();
  } catch (error) { next(error); }
};

export const requireAuth = (req: Request, res: Response, next: NextFunction): void => {
  void optionalAuth(req, res, (error?: unknown) => {
    if (error) return next(error);
    if (!req.user || !req.supabase) return next(new AppError('Authentication required.', 401, 'UNAUTHORIZED'));
    next();
  });
};

export const requireAdmin = (req: Request, _res: Response, next: NextFunction): void => {
  if (!req.user || !config.adminUserIds.includes(req.user.id)) {
    return next(new AppError('Administrator access required.', 403, 'FORBIDDEN'));
  }
  next();
};

export const adminClient = (): SupabaseClient => {
  if (!config.supabase.url || !config.supabase.serviceRoleKey) {
    throw new AppError('Administrative service is not configured.', 503, 'SERVICE_UNAVAILABLE');
  }
  return createClient(config.supabase.url, config.supabase.serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
};

export type AuthenticatedUser = User;
