import { randomUUID } from 'crypto';
import { execFile } from 'child_process';
import { Router } from 'express';
import { z } from 'zod';
import { adminClient, createSupabaseClient, requireAdmin, requireAuth } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { dbFailure, pagination, parse, sendData, sendPage } from '../utils/api';
import type { OsmArea } from '../scripts/osmQuery';

const router = Router(); const areas = ['Jaksel', 'Jakpus', 'Jakbar', 'Jaktim', 'Jakut'] as const;
let syncRunning = false;
router.get('/status', async (req, res, next) => {
  try {
    const client = adminClient();
    const [runs, ...counts] = await Promise.all([
      client.from('sync_runs').select('started_at,finished_at,status').neq('status', 'running').order('started_at', { ascending: false }).limit(1),
      ...areas.map((area) => client.from('osm_places').select('*', { count: 'exact', head: true }).eq('area', area).eq('sync_status', 'active')),
    ]);
    const error = runs.error ?? counts.find((x) => x.error)?.error; if (error) throw dbFailure(error);
    const byArea = Object.fromEntries(areas.map((area, i) => [area, counts[i].count ?? 0]));
    sendData(req, res, { last_sync: runs.data?.[0]?.finished_at ?? null, last_sync_status: runs.data?.[0]?.status ?? null, total_active_places: Object.values(byArea).reduce((a, b) => a + b, 0), by_area: byArea, attribution: '© OpenStreetMap contributors, ODbL 1.0' });
  } catch (e) { next(e); }
});
router.get('/logs', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    const { page, limit, from, to } = pagination(req.query); const filter = parse(z.object({ area: z.enum(areas).optional(), status: z.enum(['running', 'success', 'partial', 'failed']).optional() }), req.query);
    let q = adminClient().from('sync_runs').select('id,started_at,finished_at,area,found_count,inserted_count,updated_count,marked_stale_count,status', { count: 'exact' }).order('started_at', { ascending: false });
    if (filter.area) q = q.eq('area', filter.area); if (filter.status) q = q.eq('status', filter.status);
    const { data, error, count } = await q.range(from, to); if (error) throw dbFailure(error); sendPage(req, res, data ?? [], page, limit, (count ?? 0) > to + 1);
  } catch (e) { next(e); }
});
router.post('/trigger', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    const body = parse(z.object({ area: z.enum(areas).optional(), dry_run: z.boolean().optional().default(false) }).strict(), req.body);
    if (syncRunning) throw new AppError('Sinkronisasi sedang berjalan.', 409, 'SYNC_ALREADY_RUNNING');
    syncRunning = true; const jobId = randomUUID();
    const args = ['-r', 'ts-node/register', 'src/scripts/osmSync.ts', ...(body.area ? [body.area] : []), ...(body.dry_run ? ['--dry-run'] : [])];
    const child = execFile(process.execPath, args, { cwd: process.cwd(), windowsHide: true }, (err) => { syncRunning = false; if (err) console.error(`[${jobId}] OSM sync process exited with error: ${err.message}`); });
    child.on('error', (err) => { syncRunning = false; console.error(`[${jobId}] OSM sync failed to start: ${err.message}`); });
    sendData(req, res, { job_id: jobId, area: body.area ?? null, dry_run: body.dry_run, status: 'queued' }, 202);
  } catch (e) { next(e); }
});
export default router;
