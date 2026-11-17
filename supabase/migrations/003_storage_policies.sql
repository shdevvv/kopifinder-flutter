-- ============================================================
-- KopiFinder — Migration 003: Supabase Storage Buckets & Policies
-- Target: Supabase PostgreSQL & Storage Schema
-- ============================================================

-- Create storage buckets if they do not exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('review-photos', 'review-photos', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('post-photos', 'post-photos', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('cafe-photos', 'cafe-photos', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('offer-photos', 'offer-photos', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================================
-- 1. BUCKET: avatars RLS POLICIES
-- Path format: avatars/{user_id}/avatar.png
-- ============================================================
DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;
CREATE POLICY "Public can view avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================================
-- 2. BUCKET: review-photos RLS POLICIES
-- Path format: review-photos/{user_id}/{filename}
-- ============================================================
DROP POLICY IF EXISTS "Public can view review photos" ON storage.objects;
CREATE POLICY "Public can view review photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'review-photos');

DROP POLICY IF EXISTS "Users can upload own review photo" ON storage.objects;
CREATE POLICY "Users can upload own review photo"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'review-photos'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can delete own review photo" ON storage.objects;
CREATE POLICY "Users can delete own review photo"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'review-photos'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================================
-- 3. BUCKET: post-photos RLS POLICIES
-- Path format: post-photos/{user_id}/{filename}
-- ============================================================
DROP POLICY IF EXISTS "Public can view post photos" ON storage.objects;
CREATE POLICY "Public can view post photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'post-photos');

DROP POLICY IF EXISTS "Users can upload own post photo" ON storage.objects;
CREATE POLICY "Users can upload own post photo"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'post-photos'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can delete own post photo" ON storage.objects;
CREATE POLICY "Users can delete own post photo"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'post-photos'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================================
-- 4. BUCKETS: cafe-photos & offer-photos RLS POLICIES
-- Public SELECT; Upload/update/delete restricted to service_role (admin)
-- ============================================================
DROP POLICY IF EXISTS "Public can view cafe photos" ON storage.objects;
CREATE POLICY "Public can view cafe photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'cafe-photos');

DROP POLICY IF EXISTS "Public can view offer photos" ON storage.objects;
CREATE POLICY "Public can view offer photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'offer-photos');
