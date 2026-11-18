import express, { Express, Request, Response } from 'express';
import { helmetMiddleware, corsMiddleware } from './middleware/security';
import { apiRateLimiter } from './middleware/rateLimiter';
import { errorHandler } from './middleware/errorHandler';
import apiRouter from './routes';
import { requestId } from './middleware/requestId';

export const createApp = (): Express => {
  const app = express();

  app.use(requestId);

  // Security & Header Middleware
  app.use(helmetMiddleware);
  app.use(corsMiddleware);

  // Rate Limiter
  app.use(apiRateLimiter);

  // Body Parsing (limit body size)
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true, limit: '1mb' }));

  // Root Info Route
  app.get('/', (_req: Request, res: Response) => {
    res.json({
      name: 'KopiFinder API',
      status: 'online',
      version: '1.0.0',
      health: '/api/v1/health',
    });
  });

  // API v1 Router
  app.use('/api/v1', apiRouter);

  // Fallback 404 Route
  app.use((req: Request, res: Response) => {
    res.status(404).json({
      success: false,
      error: {
        code: 'NOT_FOUND',
        message: `Route ${req.method} ${req.path} not found`,
      },
      meta: { request_id: req.requestId },
    });
  });

  // Global Error Handler
  app.use(errorHandler);

  return app;
};
