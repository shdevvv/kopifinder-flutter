import { randomUUID } from 'crypto';
import { NextFunction, Request, Response } from 'express';

export const requestId = (req: Request, res: Response, next: NextFunction): void => {
  req.requestId = randomUUID();
  res.setHeader('X-Request-Id', req.requestId);
  next();
};
