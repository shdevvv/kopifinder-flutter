/**
 * osmReport.ts
 * Write sync run start/finish records to the sync_runs table.
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from '../config/env';
import type { OsmArea } from './osmQuery';

function getAdminClient(): SupabaseClient {
  return createClient(config.supabase.url, config.supabase.serviceRoleKey, {
    auth: { persistSession: false },
  });
}

export interface SyncRunRecord {
  id: string;
  started_at: string;
  area: OsmArea;
}

/** Create a sync_runs row for a single area and return its id */
export async function startSyncRun(area: OsmArea): Promise<SyncRunRecord | null> {
  const supabase = getAdminClient();

  const { data, error } = await supabase
    .from('sync_runs')
    .insert({
      area,
      status: 'started',
      records_total: 0,
      records_added: 0,
      records_updated: 0,
    })
    .select('id, started_at, area')
    .single();

  if (error) {
    console.error(`[OSM Report] Failed to create sync_run for ${area}: ${error.message}`);
    return null;
  }

  return data as SyncRunRecord;
}

export interface SyncRunFinishParams {
  runId: string;
  status: 'success' | 'partial' | 'failed';
  foundCount: number;
  insertedCount: number;
  updatedCount: number;
  markedStaleCount: number;
  errorMessage?: string;
}

/** Finish a sync_runs row with final counts and status */
export async function finishSyncRun(params: SyncRunFinishParams): Promise<void> {
  const supabase = getAdminClient();

  const { error } = await supabase
    .from('sync_runs')
    .update({
      completed_at: new Date().toISOString(),
      status: params.status === 'success' ? 'completed' : 'failed',
      records_total: params.foundCount,
      records_added: params.insertedCount,
      records_updated: params.updatedCount,
      error_message: params.errorMessage ?? null,
    })
    .eq('id', params.runId);

  if (error) {
    console.error(`[OSM Report] Failed to finish sync_run ${params.runId}: ${error.message}`);
  }
}

/** Get the last N sync runs for the status endpoint */
export async function getRecentSyncRuns(limit = 10) {
  const supabase = getAdminClient();

  const { data, error } = await supabase
    .from('sync_runs')
    .select('*')
    .order('started_at', { ascending: false })
    .limit(limit);

  if (error) {
    console.error(`[OSM Report] getRecentSyncRuns error: ${error.message}`);
    return [];
  }

  return data ?? [];
}
