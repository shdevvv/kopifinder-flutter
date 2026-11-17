import { Request, Response, NextFunction } from 'express';
import { config } from '../config/env';

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;

  constructor(message: string, statusCode = 500, code = 'INTERNAL_SERVER_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export const errorHandler = (
  err: Error | AppError,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  next: NextFunction
): void => {
  const statusCode = err instanceof AppError ? err.statusCode : 500;
  const code = err instanceof AppError ? err.code : 'INTERNAL_SERVER_ERROR';
  const message = err instanceof AppError ? err.message : 'An unexpected error occurred';

  if (statusCode >= 500) console.error(`[${req.requestId ?? 'no-request-id'}]`, err);

  // Do not expose stack traces or raw SQL errors to clients
  res.status(statusCode).json({
    success: false,
    error: {
      code,
      message,
    },
    meta: { request_id: req.requestId },
  });
};
