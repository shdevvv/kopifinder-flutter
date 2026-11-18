/**
 * osmQuery.ts
 * Query Overpass API for cafes in a Jakarta area.
 * Respects Overpass rate limits: max 1 request per 2 seconds, timeout 60s.
 * License: © OpenStreetMap contributors, ODbL 1.0
 */

export type OsmArea = 'Jaksel' | 'Jakpus' | 'Jakbar' | 'Jaktim' | 'Jakut';

export interface OsmElement {
  type: 'node' | 'way' | 'relation';
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
}

export interface OverpassResponse {
  elements: OsmElement[];
}

/** Map KopiFinder area label → OSM admin_level 5 name */
const AREA_OSM_NAMES: Record<OsmArea, string> = {
  Jaksel: 'Jakarta Selatan',
  Jakpus: 'Jakarta Pusat',
  Jakbar: 'Jakarta Barat',
  Jaktim: 'Jakarta Timur',
  Jakut: 'Jakarta Utara',
};

const OVERPASS_ENDPOINTS = [
  'https://overpass.openstreetmap.fr/api/interpreter',
  'https://lz4.overpass-api.de/api/interpreter',
  'https://z.overpass-api.de/api/interpreter',
  'https://overpass-api.de/api/interpreter',
];
const REQUEST_TIMEOUT_MS = 60_000;
const RETRY_DELAYS_MS = [3_000, 5_000, 10_000];

/** Build Overpass QL query for cafes in a named Jakarta area */
function buildQuery(areaName: string): string {
  return `
[out:json][timeout:60];
area["name"="${areaName}"]["admin_level"="5"]->.area;
(
  node["amenity"="cafe"](area.area);
  way["amenity"="cafe"](area.area);
  relation["amenity"="cafe"](area.area);
);
out center tags;
  `.trim();
}

/** Sleep helper */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Query Overpass API for cafes in a given Jakarta area.
 * Retries up to 3 times on failure with exponential backoff.
 */
export async function queryOsmCafes(area: OsmArea): Promise<OsmElement[]> {
  const areaName = AREA_OSM_NAMES[area];
  const query = buildQuery(areaName);

  for (let attempt = 0; attempt <= RETRY_DELAYS_MS.length; attempt++) {
    const endpoint = OVERPASS_ENDPOINTS[attempt % OVERPASS_ENDPOINTS.length];
    try {
      console.log(`[OSM] Querying ${area} (${areaName}), attempt ${attempt + 1} via ${new URL(endpoint).hostname}...`);

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'KopiFinderApp/1.0 (https://kopifinder.app; contact@kopifinder.app)',
        },
        body: `data=${encodeURIComponent(query)}`,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const text = await response.text().catch(() => '');
        throw new Error(`Overpass HTTP ${response.status}: ${text.slice(0, 200)}`);
      }

      const data = (await response.json()) as OverpassResponse;

      if (!Array.isArray(data.elements)) {
        throw new Error('Overpass response missing elements array');
      }

      console.log(`[OSM] ${area}: received ${data.elements.length} raw elements`);
      return data.elements;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      const isLastAttempt = attempt >= RETRY_DELAYS_MS.length;

      if (isLastAttempt) {
        console.error(`[OSM] ${area}: all attempts failed — ${message}`);
        throw new Error(`Overpass query failed for ${area} after ${attempt + 1} attempts: ${message}`);
      }

      const delay = RETRY_DELAYS_MS[attempt];
      console.warn(`[OSM] ${area}: attempt ${attempt + 1} failed (${message}), retrying in ${delay / 1000}s...`);
      await sleep(delay);
    }
  }

  // Should never reach here
  throw new Error(`queryOsmCafes: unreachable code for area ${area}`);
}
