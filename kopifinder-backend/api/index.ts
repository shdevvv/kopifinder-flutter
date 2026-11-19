import { createApp } from '../src/app';

const app = createApp();

export default function handler(req: any, res: any) {
  if (!req.url || req.url.trim() === '') {
    req.url = '/';
  }
  return app(req, res);
}
