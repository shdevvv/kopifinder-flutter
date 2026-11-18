import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { config } from '../config/env';

const supabase = createClient(config.supabase.url, config.supabase.serviceRoleKey, {
  auth: { persistSession: false },
});

async function seedCafes() {
  console.log('Seeding verified cafes from osm_places...');

  // Get up to 60 OSM places with names across Jakarta
  const { data: osmPlaces, error: osmErr } = await supabase
    .from('osm_places')
    .select('*')
    .eq('sync_status', 'active')
    .limit(60);

  if (osmErr || !osmPlaces || osmPlaces.length === 0) {
    console.error('Error fetching osm_places:', osmErr?.message);
    return;
  }

  console.log(`Found ${osmPlaces.length} OSM places to activate into curated cafes.`);

  let insertedCount = 0;

  for (const place of osmPlaces) {
    // Check if already in cafes
    const { data: existing } = await supabase
      .from('cafes')
      .select('id')
      .eq('name', place.name)
      .maybeSingle();

    if (existing) continue;

    const { data: cafe, error: cafeErr } = await supabase
      .from('cafes')
      .insert({
        name: place.name,
        address: place.address || place.address_street || `Jakarta ${place.area}`,
        area: place.area,
        latitude: place.latitude || place.lat,
        longitude: place.longitude || place.lng,
        opening_hours: place.opening_hours ? { raw: place.opening_hours } : { mon_sun: '08:00 - 22:00' },
        facilities: place.facilities && place.facilities.length > 0 ? place.facilities : ['WiFi', 'AC', 'Outdoor Seating'],
        photos: [
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800',
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
        ],
        phone: place.phone || '021-5550199',
        instagram: place.instagram || `@${place.name.toLowerCase().replace(/[^a-z0-9]/g, '')}`,
        website: place.website || null,
        description: `Spesialti kafe di area ${place.area}, Jakarta dengan suasana nyaman untuk kopi dan kerja.`,
        rating: Number((4.2 + (Math.random() * 0.7)).toFixed(1)),
        review_count: Math.floor(10 + Math.random() * 80),
        price_min: 25000,
        price_max: 65000,
        verification_status: 'verified',
        is_active: true,
      })
      .select('id')
      .single();

    if (cafeErr || !cafe) {
      console.error(`Failed to insert cafe ${place.name}:`, cafeErr?.message);
      continue;
    }

    insertedCount++;

    // Link in cafe_place_links
    await supabase.from('cafe_place_links').upsert({
      cafe_id: cafe.id,
      osm_place_id: place.id,
      match_confidence: 1.0,
    }, { onConflict: 'cafe_id,osm_place_id' });

    // Add 2 menu items
    await supabase.from('menus').insert([
      {
        cafe_id: cafe.id,
        name: 'Signature Iced Latte',
        description: 'Espresso blend lokal dengan susu segar pilihan.',
        price: 38000,
        category: 'Coffee',
        is_available: true,
      },
      {
        cafe_id: cafe.id,
        name: 'Manual Brew V60 (Single Origin)',
        description: 'Biji kopi pilihan Nusantara diseduh dengan teknik pour-over V60.',
        price: 42000,
        category: 'Filter Coffee',
        is_available: true,
      },
    ]);
  }

  // Add sample offers for top 3 cafes
  const { data: topCafes } = await supabase.from('cafes').select('id, name').limit(3);
  if (topCafes) {
    for (const c of topCafes) {
      await supabase.from('offers').insert({
        cafe_id: c.id,
        title: 'Diskon 20% Morning Coffee',
        description: 'Nikmati potongan 20% untuk semua menu kopi sebelum jam 11:00.',
        original_price: 40000,
        discounted_price: 32000,
        valid_until: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        is_active: true,
      });
    }
  }

  console.log(`Successfully activated and linked ${insertedCount} curated cafes with menus and offers!`);
}

seedCafes();
