import { Request, Response } from 'express';
import { ZodError, ZodType } from 'zod';
import { AppError } from '../middleware/errorHandler';

export const parse = <T>(schema: ZodType<T>, value: unknown): T => {
  const result = schema.safeParse(value);
  if (!result.success) throw new AppError('Periksa kembali data yang dikirim.', 400, 'VALIDATION_ERROR');
  return result.data;
};

export const sendData = (req: Request, res: Response, data: unknown, status = 200): void => {
  res.status(status).json({ success: true, data, meta: { request_id: req.requestId } });
};

export const sendPage = (req: Request, res: Response, data: unknown[], page: number, limit: number, hasMore: boolean): void => {
  res.json({ success: true, data, meta: { page, limit, has_more: hasMore, next_cursor: null, request_id: req.requestId } });
};

export const pagination = (query: Request['query']) => {
  const page = Number(query.page ?? 1);
  const limit = Number(query.limit ?? 20);
  if (!Number.isInteger(page) || page < 1 || !Number.isInteger(limit) || limit < 1 || limit > 50) {
    throw new AppError('page harus >= 1 dan limit harus 1-50.', 400, 'VALIDATION_ERROR');
  }
  return { page, limit, from: (page - 1) * limit, to: page * limit - 1 };
};

export const dbFailure = (error: unknown): AppError => {
  const e = error as { code?: string; message?: string };
  if (e?.code === '23505') return new AppError('Data sudah tersedia.', 409, 'CONFLICT');
  if (e?.code === '23503') return new AppError('Referensi data tidak ditemukan.', 404, 'NOT_FOUND');
  return new AppError('Permintaan tidak dapat diproses saat ini.', 500, 'DATABASE_ERROR');
};

export const validationIssues = (error: ZodError) => error.issues.map(({ path, message }) => ({ path: path.join('.'), message }));

export const isOwnedStorageObject = (value: string | null | undefined, bucket: string, userId: string, supabaseUrl: string): boolean => {
  if (value == null) return true;
  const expected = `${bucket}/${userId}/`;
  if (value.startsWith(expected)) return value.length > expected.length;
  try {
    const parsed = new URL(value);
    const project = new URL(supabaseUrl);
    return parsed.origin === project.origin && parsed.pathname.startsWith(`/storage/v1/object/public/${expected}`);
  } catch { return false; }
};
