/**
 * osmSync.ts
 * Main OSM sync orchestrator.
 * Usage:
 *   npx ts-node src/scripts/osmSync.ts           → sync all 5 areas
 *   npx ts-node src/scripts/osmSync.ts Jaksel    → sync single area (testing)
 *
 * License compliance:
 *   Data sourced from © OpenStreetMap contributors under ODbL 1.0.
 *   Attribution must appear in app UI (Map Screen, footer).
 */

import 'dotenv/config';
import { queryOsmCafes, type OsmArea } from './osmQuery';
import { transformElements } from './osmTransform';
import { upsertOsmPlaces, markStaleRecords, getOsmPlacesCountByArea } from './osmUpsert';
import { startSyncRun, finishSyncRun } from './osmReport';

const ALL_AREAS: OsmArea[] = ['Jaksel', 'Jakpus', 'Jakbar', 'Jaktim', 'Jakut'];
const INTER_AREA_DELAY_MS = 3_000; // 3 second pause between area queries (Overpass courtesy)

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

interface AreaSyncResult {
  area: OsmArea;
  status: 'success' | 'partial' | 'failed';
  found: number;
  transformed: number;
  inserted: number;
  updated: number;
  markedStale: number;
  errors: string[];
  durationMs: number;
}

/** Sync a single area end-to-end */
async function syncArea(area: OsmArea): Promise<AreaSyncResult> {
  const startedAt = new Date();
  const run = await startSyncRun(area);

  const result: AreaSyncResult = {
    area,
    status: 'failed',
    found: 0,
    transformed: 0,
    inserted: 0,
    updated: 0,
    markedStale: 0,
    errors: [],
    durationMs: 0,
  };

  try {
    // 1. Query Overpass API
    const elements = await queryOsmCafes(area);
    result.found = elements.length;

    // 2. Transform & filter
    const rows = transformElements(elements, area);
    result.transformed = rows.length;
    console.log(`[Sync] ${area}: ${result.found} raw → ${result.transformed} valid places`);

    if (rows.length === 0) {
      result.status = 'partial';
      result.errors.push('No valid cafe elements after transformation');
    } else {
      // 3. Upsert to Supabase
      const upsertResult = await upsertOsmPlaces(rows);
      result.inserted = upsertResult.inserted;
      result.updated = upsertResult.updated;
      result.errors.push(...upsertResult.errors);

      // 4. Mark stale (places not seen in last 30 days for this area)
      result.markedStale = await markStaleRecords(area, startedAt);

      result.status = upsertResult.errors.length > 0 ? 'partial' : 'success';
    }
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    result.errors.push(message);
    result.status = 'failed';
    console.error(`[Sync] ${area}: FAILED — ${message}`);
  }

  result.durationMs = Date.now() - startedAt.getTime();

  // Write to sync_runs
  if (run) {
    await finishSyncRun({
      runId: run.id,
      status: result.status,
      foundCount: result.found,
      insertedCount: result.inserted,
      updatedCount: result.updated,
      markedStaleCount: result.markedStale,
      errorMessage: result.errors.length > 0 ? result.errors.join('; ') : undefined,
    });
  }

  return result;
}

/** Main entry point */
async function main(): Promise<void> {
  const arg = process.argv[2];
  const areas: OsmArea[] = arg && ALL_AREAS.includes(arg as OsmArea)
    ? [arg as OsmArea]
    : ALL_AREAS;

  console.log(`\n${'='.repeat(60)}`);
  console.log(`KopiFinder OSM Sync — ${new Date().toISOString()}`);
  console.log(`Areas: ${areas.join(', ')}`);
  console.log(`${'='.repeat(60)}\n`);

  const allResults: AreaSyncResult[] = [];

  for (let i = 0; i < areas.length; i++) {
    const area = areas[i];
    console.log(`\n[Sync] Starting ${area} (${i + 1}/${areas.length})...`);

    const result = await syncArea(area);
    allResults.push(result);

    console.log(`[Sync] ${area}: ${result.status.toUpperCase()} — found=${result.found}, ` +
      `valid=${result.transformed}, inserted=${result.inserted}, ` +
      `stale=${result.markedStale}, errors=${result.errors.length} (${result.durationMs}ms)`);

    // Courtesy delay between areas (avoid hammering Overpass)
    if (i < areas.length - 1) {
      console.log(`[Sync] Waiting ${INTER_AREA_DELAY_MS / 1000}s before next area...`);
      await sleep(INTER_AREA_DELAY_MS);
    }
  }

  // Final summary
  console.log(`\n${'='.repeat(60)}`);
  console.log('SYNC SUMMARY');
  console.log('='.repeat(60));

  let totalFound = 0, totalInserted = 0, totalStale = 0;
  for (const r of allResults) {
    const icon = r.status === 'success' ? '✅' : r.status === 'partial' ? '⚠️' : '❌';
    console.log(`${icon} ${r.area.padEnd(8)} | found=${String(r.found).padStart(4)} | ` +
      `valid=${String(r.transformed).padStart(4)} | inserted=${String(r.inserted).padStart(4)} | ` +
      `stale=${r.markedStale} | ${r.durationMs}ms`);
    totalFound += r.found;
    totalInserted += r.inserted;
    totalStale += r.markedStale;
  }

  console.log('-'.repeat(60));
  console.log(`TOTAL: found=${totalFound}, inserted=${totalInserted}, staleMarked=${totalStale}`);

  // DB counts
  try {
    const counts = await getOsmPlacesCountByArea();
    console.log('\nActive osm_places in database:');
    for (const [area, count] of Object.entries(counts)) {
      console.log(`  ${area}: ${count} active places`);
    }
  } catch {
    console.warn('Could not fetch DB counts (Supabase credentials may not be set)');
  }

  console.log('='.repeat(60));
  console.log('Sync complete.\n');

  const anyFailed = allResults.some((r) => r.status === 'failed');
  process.exit(anyFailed ? 1 : 0);
}

main().catch((err) => {
  console.error('[Sync] Unhandled error:', err);
  process.exit(1);
});
