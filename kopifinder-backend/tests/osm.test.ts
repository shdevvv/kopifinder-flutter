/**
 * osm.test.ts
 * Unit tests for Phase 3 OSM sync pipeline.
 * Tests: transform logic, deduplication, validation.
 * Does NOT hit live Overpass API or Supabase (uses mocks).
 */

import { transformElement, transformElements } from '../src/scripts/osmTransform';
import type { OsmElement } from '../src/scripts/osmQuery';

// ─── Mock OSM Elements ────────────────────────────────────────────────────────

const validNode: OsmElement = {
  type: 'node',
  id: 123456789,
  lat: -6.2297,
  lon: 106.8295,
  tags: {
    name: 'Tanamera Coffee Roasters',
    amenity: 'cafe',
    phone: '+62-21-5205299',
    'contact:instagram': 'tanameracoffee',
    'opening_hours': 'Mo-Fr 08:00-22:00; Sa-Su 09:00-22:00',
    'internet_access': 'wlan',
    'outdoor_seating': 'yes',
    'addr:street': 'Jl. Kemang Raya',
    'addr:housenumber': 'No. 1',
  },
};

const validWay: OsmElement = {
  type: 'way',
  id: 987654321,
  center: { lat: -6.1954, lon: 106.8229 },
  tags: {
    name: 'Giyanti Coffee Roastery',
    amenity: 'cafe',
    'internet_access': 'wlan',
    'addr:full': 'Jl. Suryo No. 32, Kebayoran Baru, Jakarta Selatan',
  },
};

const noNameNode: OsmElement = {
  type: 'node',
  id: 111,
  lat: -6.21,
  lon: 106.84,
  tags: { amenity: 'cafe' },
};

const noCoordNode: OsmElement = {
  type: 'node',
  id: 222,
  tags: { name: 'Ghost Cafe' },
};

const outOfBoundsNode: OsmElement = {
  type: 'node',
  id: 333,
  lat: -7.5, // outside Jakarta bounding box
  lon: 110.0,
  tags: { name: 'Cafe Luar Jakarta' },
};

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('Phase 3: osmTransform — transformElement', () => {
  test('T01: transforms valid node with all fields', () => {
    const result = transformElement(validNode, 'Jaksel');
    expect(result).not.toBeNull();
    expect(result!.name).toBe('Tanamera Coffee Roasters');
    expect(result!.osm_type).toBe('node');
    expect(result!.osm_id).toBe(123456789);
    expect(result!.area).toBe('Jaksel');
    expect(result!.lat).toBeCloseTo(-6.2297);
    expect(result!.lng).toBeCloseTo(106.8295);
    expect(result!.phone).toBe('+62-21-5205299');
    expect(result!.instagram).toBe('tanameracoffee');
    expect(result!.opening_hours).toBe('Mo-Fr 08:00-22:00; Sa-Su 09:00-22:00');
    expect(result!.facilities).toContain('WiFi');
    expect(result!.facilities).toContain('Outdoor Seating');
    expect(result!.sync_status).toBe('active');
    expect(result!.source_url).toContain('openstreetmap.org/node/123456789');
  });

  test('T02: transforms valid way using center coordinates', () => {
    const result = transformElement(validWay, 'Jaksel');
    expect(result).not.toBeNull();
    expect(result!.osm_type).toBe('way');
    expect(result!.lat).toBeCloseTo(-6.1954);
    expect(result!.lng).toBeCloseTo(106.8229);
    expect(result!.address).toBe('Jl. Suryo No. 32, Kebayoran Baru, Jakarta Selatan');
  });

  test('T03: returns null for element without name', () => {
    const result = transformElement(noNameNode, 'Jaksel');
    expect(result).toBeNull();
  });

  test('T04: returns null for element without coordinates', () => {
    const result = transformElement(noCoordNode, 'Jaksel');
    expect(result).toBeNull();
  });

  test('T05: returns null for element outside Jakarta bounding box', () => {
    const result = transformElement(outOfBoundsNode, 'Jaksel');
    expect(result).toBeNull();
  });
});

describe('Phase 3: osmTransform — transformElements (batch)', () => {
  test('T06: filters invalids and returns only valid rows', () => {
    const elements = [validNode, validWay, noNameNode, noCoordNode, outOfBoundsNode];
    const rows = transformElements(elements, 'Jaksel');
    expect(rows.length).toBe(2);
    expect(rows.map((r) => r.name)).toContain('Tanamera Coffee Roasters');
    expect(rows.map((r) => r.name)).toContain('Giyanti Coffee Roastery');
  });

  test('T07: deduplicates elements with same osm_type+osm_id', () => {
    const duplicated = [validNode, validNode, validNode];
    const rows = transformElements(duplicated, 'Jaksel');
    expect(rows.length).toBe(1);
  });

  test('T08: handles empty input gracefully', () => {
    const rows = transformElements([], 'Jakpus');
    expect(rows).toEqual([]);
  });

  test('T09: assigns correct area to all rows', () => {
    const rows = transformElements([validNode, validWay], 'Jakbar');
    rows.forEach((r) => expect(r.area).toBe('Jakbar'));
  });

  test('T10: last_seen_at is a valid ISO date string', () => {
    const rows = transformElements([validNode], 'Jaksel');
    expect(rows.length).toBe(1);
    expect(() => new Date(rows[0].last_seen_at)).not.toThrow();
    expect(new Date(rows[0].last_seen_at).getFullYear()).toBeGreaterThanOrEqual(2024);
  });
});

describe('Phase 3: osmTransform — facility extraction', () => {
  test('T11: detects no facilities when none in tags', () => {
    const bare: OsmElement = {
      type: 'node', id: 999, lat: -6.2, lon: 106.8,
      tags: { name: 'Plain Cafe', amenity: 'cafe' },
    };
    const result = transformElement(bare, 'Jaksel');
    expect(result!.facilities).toEqual([]);
  });

  test('T12: detects multiple facilities', () => {
    const rich: OsmElement = {
      type: 'node', id: 1001, lat: -6.21, lon: 106.82,
      tags: {
        name: 'Rich Facility Cafe',
        amenity: 'cafe',
        'internet_access': 'wlan',
        'outdoor_seating': 'yes',
        'air_conditioning': 'yes',
        'parking': 'yes',
        'toilet': 'yes',
        'takeaway': 'yes',
      },
    };
    const result = transformElement(rich, 'Jakpus');
    expect(result!.facilities).toContain('WiFi');
    expect(result!.facilities).toContain('Outdoor Seating');
    expect(result!.facilities).toContain('AC');
    expect(result!.facilities).toContain('Parkir');
    expect(result!.facilities).toContain('Toilet');
    expect(result!.facilities).toContain('Takeaway');
  });
});
