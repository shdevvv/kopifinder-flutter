/**
 * osmTransform.ts
 * Transform raw OSM elements into osm_places table row format.
 * - Only includes elements with a valid name AND valid coordinates.
 * - Never fabricates data not present in OSM tags.
 * License: © OpenStreetMap contributors, ODbL 1.0
 */

import type { OsmArea, OsmElement } from './osmQuery';

export interface OsmPlaceRow {
  osm_type: 'node' | 'way' | 'relation';
  osm_id: number;
  name: string;
  area: OsmArea;
  address: string | null;
  lat: number;
  lng: number;
  latitude?: number;
  longitude?: number;
  phone: string | null;
  website: string | null;
  instagram: string | null;
  opening_hours: string | null;
  facilities: string[];
  osm_tags: Record<string, string>;
  source_url: string;
  sync_status: 'active';
  last_seen_at: string; // ISO string
}

/** Extract OSM facilities based on known tags */
function extractFacilities(tags: Record<string, string>): string[] {
  const facilities: string[] = [];
  if (tags['internet_access'] === 'wlan' || tags['wifi'] === 'yes') facilities.push('WiFi');
  if (tags['outdoor_seating'] === 'yes') facilities.push('Outdoor Seating');
  if (tags['indoor_seating'] === 'yes' || tags['seating'] === 'indoor') facilities.push('Indoor Seating');
  if (tags['air_conditioning'] === 'yes') facilities.push('AC');
  if (tags['parking'] === 'yes' || tags['amenity:parking'] === 'yes') facilities.push('Parkir');
  if (tags['smoking'] === 'yes' || tags['smoking'] === 'separated') facilities.push('Area Merokok');
  if (tags['dog'] === 'yes' || tags['animals'] === 'yes') facilities.push('Pet Friendly');
  if (tags['toilet'] === 'yes' || tags['toilets'] === 'yes') facilities.push('Toilet');
  if (tags['takeaway'] === 'yes') facilities.push('Takeaway');
  if (tags['delivery'] === 'yes') facilities.push('Delivery');
  return facilities;
}

/** Build a human-readable address from addr:* tags */
function buildAddress(tags: Record<string, string>): string | null {
  if (tags['addr:full']) return tags['addr:full'];
  const parts: string[] = [];
  if (tags['addr:street']) parts.push(tags['addr:street']);
  if (tags['addr:housenumber']) parts.push(`No. ${tags['addr:housenumber']}`);
  if (tags['addr:suburb']) parts.push(tags['addr:suburb']);
  if (tags['addr:city']) parts.push(tags['addr:city']);
  return parts.length > 0 ? parts.join(', ') : null;
}

/** Get phone from phone or contact:phone */
function extractPhone(tags: Record<string, string>): string | null {
  return tags['phone'] || tags['contact:phone'] || tags['contact:mobile'] || null;
}

/** Get website from website or contact:website */
function extractWebsite(tags: Record<string, string>): string | null {
  return tags['website'] || tags['contact:website'] || null;
}

/** Get instagram from contact:instagram */
function extractInstagram(tags: Record<string, string>): string | null {
  const ig = tags['contact:instagram'] || tags['instagram'] || null;
  if (!ig) return null;
  // Strip URL prefix if present
  return ig.replace(/^https?:\/\/(www\.)?instagram\.com\/?/i, '').replace(/\/$/, '');
}

/** Resolve lat/lng from node (direct) or way/relation (center) */
function resolveCoords(el: OsmElement): { lat: number; lng: number } | null {
  if (el.type === 'node' && el.lat != null && el.lon != null) {
    return { lat: el.lat, lng: el.lon };
  }
  if ((el.type === 'way' || el.type === 'relation') && el.center) {
    return { lat: el.center.lat, lng: el.center.lon };
  }
  return null;
}

/**
 * Transform a single OSM element into an OsmPlaceRow.
 * Returns null if the element is invalid (no name or no coordinates).
 */
export function transformElement(el: OsmElement, area: OsmArea): OsmPlaceRow | null {
  const tags = el.tags ?? {};

  // Skip: no name
  const name = tags['name'] || tags['name:en'] || tags['name:id'];
  if (!name || name.trim().length < 2) return null;

  // Skip: no coordinates
  const coords = resolveCoords(el);
  if (!coords) return null;

  // Validate coordinate bounds for Jakarta (rough bounding box)
  if (coords.lat < -6.4 || coords.lat > -6.0 || coords.lng < 106.6 || coords.lng > 107.0) {
    return null;
  }

  return {
    osm_type: el.type,
    osm_id: el.id,
    name: name.trim(),
    area,
    address: buildAddress(tags),
    lat: coords.lat,
    lng: coords.lng,
    latitude: coords.lat,
    longitude: coords.lng,
    phone: extractPhone(tags),
    website: extractWebsite(tags),
    instagram: extractInstagram(tags),
    opening_hours: tags['opening_hours'] || null,
    facilities: extractFacilities(tags),
    osm_tags: tags,
    source_url: `https://www.openstreetmap.org/${el.type}/${el.id}`,
    sync_status: 'active',
    last_seen_at: new Date().toISOString(),
  };
}

/**
 * Transform a batch of OSM elements, filtering out invalids.
 * Returns only valid, unique OsmPlaceRows (deduped by osm_type+osm_id).
 */
export function transformElements(elements: OsmElement[], area: OsmArea): OsmPlaceRow[] {
  const seen = new Set<string>();
  const rows: OsmPlaceRow[] = [];

  for (const el of elements) {
    const key = `${el.type}:${el.id}`;
    if (seen.has(key)) continue;
    seen.add(key);

    const row = transformElement(el, area);
    if (row) rows.push(row);
  }

  return rows;
}
