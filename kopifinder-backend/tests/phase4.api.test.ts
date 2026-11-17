import request from 'supertest';
import { createApp } from '../src/app';

const app = createApp();

describe('Phase 4 API routing, validation, and access controls', () => {
  it('returns request IDs and standard success envelopes for liveness', async () => {
    const response = await request(app).get('/api/v1/health').expect(200);
    expect(response.headers['x-request-id']).toBeTruthy();
    expect(response.body).toMatchObject({ success: true, meta: { request_id: response.headers['x-request-id'] } });
  });

  it.each([
    ['GET', '/api/v1/users/me'],
    ['GET', '/api/v1/ai/history'],
    ['GET', '/api/v1/sync/logs'],
    ['POST', '/api/v1/posts'],
    ['POST', '/api/v1/sync/trigger'],
  ])('%s %s rejects anonymous requests', async (method, url) => {
    const response = await request(app)[method.toLowerCase() as 'get' | 'post'](url).expect(401);
    expect(response.body).toMatchObject({ success: false, error: { code: 'UNAUTHORIZED' } });
  });

  it.each([
    '/api/v1/places?area=Invalid',
    '/api/v1/cafes?sort=distance',
    '/api/v1/cafes?page=0',
    '/api/v1/offers?limit=51',
  ])('rejects invalid public query parameters at %s', async (url) => {
    const response = await request(app).get(url).expect(400);
    expect(response.body).toMatchObject({ success: false, error: { code: 'VALIDATION_ERROR' } });
    expect(response.body.meta.request_id).toBe(response.headers['x-request-id']);
  });

  it('does not include internal errors in dependency failures', async () => {
    const response = await request(app).get('/api/v1/health/ready').expect(503);
    expect(response.body).toMatchObject({ success: false, error: { code: 'NOT_READY' } });
    expect(JSON.stringify(response.body)).not.toMatch(/SUPABASE|service.role|stack|password/i);
  });
});
