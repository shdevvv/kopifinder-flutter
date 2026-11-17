import fs from 'fs';
import path from 'path';

describe('Database Migration Files Verification (v2.0)', () => {
  const migrationsDir = path.resolve(__dirname, '../../supabase/migrations');
  const masterSchemaPath = path.resolve(__dirname, '../../database_schema.sql');

  it('should have all 3 migration files present in supabase/migrations/', () => {
    expect(fs.existsSync(path.join(migrationsDir, '001_initial_schema.sql'))).toBe(true);
    expect(fs.existsSync(path.join(migrationsDir, '002_rls_policies.sql'))).toBe(true);
    expect(fs.existsSync(path.join(migrationsDir, '003_storage_policies.sql'))).toBe(true);
    expect(fs.existsSync(masterSchemaPath)).toBe(true);
  });

  it('001_initial_schema.sql should define all 14 required tables', () => {
    const content = fs.readFileSync(path.join(migrationsDir, '001_initial_schema.sql'), 'utf-8');
    const requiredTables = [
      'users',
      'osm_places',
      'cafes',
      'cafe_place_links',
      'menus',
      'reviews',
      'saved_cafes',
      'posts',
      'post_likes',
      'comments',
      'comment_likes',
      'ai_recommendation_history',
      'offers',
      'sync_runs',
    ];

    requiredTables.forEach((table) => {
      expect(content).toContain(`CREATE TABLE IF NOT EXISTS public.${table}`);
    });
  });

  it('002_rls_policies.sql should enable RLS on all 14 tables and define policies', () => {
    const content = fs.readFileSync(path.join(migrationsDir, '002_rls_policies.sql'), 'utf-8');
    const requiredTables = [
      'users',
      'osm_places',
      'cafes',
      'cafe_place_links',
      'menus',
      'reviews',
      'saved_cafes',
      'posts',
      'post_likes',
      'comments',
      'comment_likes',
      'ai_recommendation_history',
      'offers',
      'sync_runs',
    ];

    requiredTables.forEach((table) => {
      expect(content).toContain(`ALTER TABLE public.${table} ENABLE ROW LEVEL SECURITY;`);
    });

    expect(content).toContain('CREATE POLICY "Users can view own profile"');
    expect(content).toContain('CREATE POLICY "Public can view active osm places"');
    expect(content).toContain('CREATE POLICY "Public can view verified cafes"');
    expect(content).toContain('CREATE POLICY "Users can insert own review"');
    expect(content).toContain('CREATE POLICY "Users can view own saved cafes"');
  });

  it('003_storage_policies.sql should define all 5 storage buckets and storage RLS', () => {
    const content = fs.readFileSync(path.join(migrationsDir, '003_storage_policies.sql'), 'utf-8');
    const buckets = ['avatars', 'review-photos', 'post-photos', 'cafe-photos', 'offer-photos'];

    buckets.forEach((bucket) => {
      expect(content).toContain(`'${bucket}'`);
    });

    expect(content).toContain('CREATE POLICY "Users can upload own avatar"');
    expect(content).toContain('CREATE POLICY "Users can upload own review photo"');
    expect(content).toContain('CREATE POLICY "Users can upload own post photo"');
  });
});
