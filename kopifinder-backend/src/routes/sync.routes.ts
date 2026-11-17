/**
 * sync.routes.ts
 * GET  /api/v1/sync/status   → last sync summary + osm_places count per area (public)
 * GET  /api/v1/sync/logs     → last 10 sync_runs records (public)
 * POST /api/v1/sync/trigger  → manually trigger OSM sync (admin only, non-blocking)
 */

import { Router, Request, Response, NextFunction } from 'express';
import { createClient } from '@supabase/supabase-js';
import { config } from '../config/env';
import type { OsmArea } from '../scripts/osmQuery';

const router = Router();

function getAdminClient() {
  return createClient(config.supabase.url, config.supabase.serviceRoleKey, {
    auth: { persistSession: false },
  });
}

// ─── GET /sync/status ────────────────────────────────────────────────────────
router.get('/status', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const supabase = getAdminClient();
    const areas: OsmArea[] = ['Jaksel', 'Jakpus', 'Jakbar', 'Jaktim', 'Jakut'];

    // Last completed sync run (any area)
    const { data: lastRun } = await supabase
      .from('sync_runs')
      .select('started_at, finished_at, status, found_count, inserted_count')
      .neq('status', 'running')
      .order('started_at', { ascending: false })
      .limit(1)
      .single();

    // Count active osm_places per area
    const byArea: Record<string, number> = {};
    let total = 0;
    for (const area of areas) {
      const { count } = await supabase
        .from('osm_places')
        .select('*', { count: 'exact', head: true })
        .eq('area', area)
        .eq('sync_status', 'active');
      byArea[area] = count ?? 0;
      total += count ?? 0;
    }

    res.json({
      success: true,
      data: {
        last_sync: lastRun?.finished_at ?? null,
        last_sync_status: lastRun?.status ?? null,
        total_active_places: total,
        by_area: byArea,
        attribution: '© OpenStreetMap contributors, ODbL 1.0',
      },
    });
  } catch (err) {
    next(err);
  }
});

// ─── GET /sync/logs ───────────────────────────────────────────────────────────
router.get('/logs', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const supabase = getAdminClient();
    const limit = Math.min(parseInt(String(req.query.limit ?? '10'), 10), 50);

    const { data, error } = await supabase
      .from('sync_runs')
      .select('*')
      .order('started_at', { ascending: false })
      .limit(limit);

    if (error) throw new Error(error.message);

    res.json({ success: true, data: data ?? [] });
  } catch (err) {
    next(err);
  }
});

// ─── POST /sync/trigger ───────────────────────────────────────────────────────
router.post('/trigger', async (req: Request, res: Response, next: NextFunction) => {
  try {
    // Admin auth: check x-admin-token header matches env
    const adminToken = req.headers['x-admin-token'];
    if (!adminToken || adminToken !== process.env.ADMIN_SYNC_TOKEN) {
      res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'Invalid admin token' },
      });
      return;
    }

    const area = req.body?.area as OsmArea | undefined;
    const validAreas: OsmArea[] = ['Jaksel', 'Jakpus', 'Jakbar', 'Jaktim', 'Jakut'];

    if (area && !validAreas.includes(area)) {
      res.status(400).json({
        success: false,
        error: { code: 'INVALID_AREA', message: `Area must be one of: ${validAreas.join(', ')}` },
      });
      return;
    }

    // Trigger sync in background (non-blocking)
    const { execFile } = await import('child_process');
    const args = area ? ['src/scripts/osmSync.ts', area] : ['src/scripts/osmSync.ts'];
    execFile('npx', ['ts-node', ...args], { cwd: process.cwd() }, (err) => {
      if (err) console.error('[Sync Trigger] Background sync error:', err.message);
    });

    res.json({
      success: true,
      data: {
        message: `OSM sync triggered for: ${area ?? 'all areas'}`,
        note: 'Sync runs in background. Check GET /api/v1/sync/logs for progress.',
      },
    });
  } catch (err) {
    next(err);
  }
});

export default router;
