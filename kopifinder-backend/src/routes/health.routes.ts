import { Router, Request, Response } from 'express';
import { config } from '../config/env';
import { createSupabaseClient } from '../middleware/auth';

const router = Router();

/**
 * GET /api/v1/health
 * Public health check endpoint
 */
router.get('/', (req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    data: {
      status: 'ok',
      service: 'kopifinder-backend',
      environment: config.env,
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    },
    meta: { request_id: req.requestId },
  });
});

router.get('/ready', async (req: Request, res: Response) => {
  try {
    const { error } = await createSupabaseClient().from('osm_places').select('id').limit(1);
    if (error) throw error;
    res.status(200).json({ success: true, data: { status: 'ready', dependencies: { supabase: 'ok' } }, meta: { request_id: req.requestId } });
  } catch {
    res.status(503).json({ success: false, error: { code: 'NOT_READY', message: 'Required dependency is unavailable.' }, meta: { request_id: req.requestId } });
  }
});

export default router;
