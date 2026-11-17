import { Router, Request, Response } from 'express';
import { config } from '../config/env';

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
  });
});

export default router;
