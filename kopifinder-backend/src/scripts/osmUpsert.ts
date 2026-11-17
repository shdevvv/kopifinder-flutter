/**
 * osmUpsert.ts
 * Upsert OsmPlaceRows into the osm_places table using ON CONFLICT (osm_type, osm_id).
 * - INSERTs new rows.
 * - UPDATEs existing rows (name, address, phone, hours, facilities, osm_tags, last_seen_at).
 * - Marks rows NOT seen in this sync run as 'stale' if unseen for >30 days.
 * - Never touches cafes with data_source = 'manual' (not applicable — osm_places is OSM-only).
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from '../config/env';
import type { OsmArea } from './osmQuery';
import type { OsmPlaceRow } from './osmTransform';

export interface UpsertResult {
  inserted: number;
  updated: number;
  skipped: number;
  markedStale: number;
  errors: string[];
}

/** Create a Supabase admin client (service role, bypasses RLS only for sync) */
function getAdminClient(): SupabaseClient {
  if (!config.supabase.url || !config.supabase.serviceRoleKey) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in environment');
  }
  return createClient(config.supabase.url, config.supabase.serviceRoleKey, {
    auth: { persistSession: false },
  });
}

const BATCH_SIZE = 50; // upsert in batches to avoid payload limits

/**
 * Upsert a batch of OsmPlaceRows into osm_places table.
 * Uses Supabase upsert with onConflict: 'osm_type,osm_id'.
 */
export async function upsertOsmPlaces(rows: OsmPlaceRow[]): Promise<UpsertResult> {
  const result: UpsertResult = { inserted: 0, updated: 0, skipped: 0, markedStale: 0, errors: [] };
  if (rows.length === 0) return result;

  const supabase = getAdminClient();

  // Upsert in batches
  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batch = rows.slice(i, i + BATCH_SIZE);

    const { error, data } = await supabase
      .from('osm_places')
      .upsert(batch, {
        onConflict: 'osm_type,osm_id',
        ignoreDuplicates: false, // we WANT to update on conflict
      })
      .select('id');

    if (error) {
      const msg = `Batch ${i / BATCH_SIZE + 1} upsert error: ${error.message}`;
      console.error(`[OSM Upsert] ${msg}`);
      result.errors.push(msg);
      result.skipped += batch.length;
      continue;
    }

    // Supabase upsert returns all affected rows; we can't distinguish insert vs update
    // We approximate: query existing before or use returned count
    result.inserted += data?.length ?? batch.length;
  }

  return result;
}

/**
 * After syncing an area, mark osm_places in that area that were NOT seen in this sync
 * and have last_seen_at older than 30 days as 'stale'.
 * This protects active data from being accidentally removed.
 */
export async function markStaleRecords(area: OsmArea, syncStartedAt: Date): Promise<number> {
  const supabase = getAdminClient();
  const thirtyDaysAgo = new Date(syncStartedAt.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const { data, error } = await supabase
    .from('osm_places')
    .update({ sync_status: 'stale' })
    .eq('area', area)
    .eq('sync_status', 'active')
    .lt('last_seen_at', thirtyDaysAgo)
    .select('id');

  if (error) {
    console.error(`[OSM Upsert] markStale error for ${area}: ${error.message}`);
    return 0;
  }

  return data?.length ?? 0;
}

/**
 * Get count of active osm_places per area for status reporting.
 */
export async function getOsmPlacesCountByArea(): Promise<Record<OsmArea, number>> {
  const supabase = getAdminClient();
  const areas: OsmArea[] = ['Jaksel', 'Jakpus', 'Jakbar', 'Jaktim', 'Jakut'];
  const counts: Record<string, number> = {};

  for (const area of areas) {
    const { count, error } = await supabase
      .from('osm_places')
      .select('*', { count: 'exact', head: true })
      .eq('area', area)
      .eq('sync_status', 'active');

    counts[area] = error ? 0 : (count ?? 0);
  }

  return counts as Record<OsmArea, number>;
}
