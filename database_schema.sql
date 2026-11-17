-- ============================================================
-- KopiFinder — Complete Master Database Migration (v2.0)
-- Target: Supabase PostgreSQL
-- Instructions: Run in Supabase SQL Editor → New Query
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- 1. TABLE: users
-- References auth.users(id)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL CHECK (char_length(name) >= 2 AND char_length(name) <= 100),
  username        TEXT NOT NULL UNIQUE CHECK (
                    char_length(username) >= 3 AND
                    char_length(username) <= 30 AND
                    username ~ '^[a-zA-Z0-9_]+$'
                  ),
  email           TEXT UNIQUE,
  avatar_url      TEXT,
  location        TEXT CHECK (char_length(location) <= 100),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. TABLE: osm_places
-- Raw catalog from OpenStreetMap ingestion
-- ============================================================
CREATE TABLE IF NOT EXISTS public.osm_places (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  osm_type        TEXT NOT NULL CHECK (osm_type IN ('node', 'way', 'relation')),
  osm_id          BIGINT NOT NULL,
  name            TEXT NOT NULL,
  area            TEXT CHECK (area IN ('Jaksel', 'Jakpus', 'Jakbar', 'Jaktim', 'Jakut')),
  address         TEXT,
  lat             DOUBLE PRECISION NOT NULL CHECK (lat BETWEEN -90 AND 90),
  lng             DOUBLE PRECISION NOT NULL CHECK (lng BETWEEN -180 AND 180),
  phone           TEXT,
  website         TEXT,
  instagram       TEXT,
  opening_hours   TEXT,
  facilities      TEXT[] NOT NULL DEFAULT '{}',
  osm_tags        JSONB NOT NULL DEFAULT '{}',
  source_url      TEXT,
  last_seen_at    TIMESTAMPTZ,
  last_synced_at  TIMESTAMPTZ,
  sync_status     TEXT NOT NULL DEFAULT 'active' CHECK (sync_status IN ('active', 'stale', 'removed')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_osm_place UNIQUE (osm_type, osm_id)
);

-- ============================================================
-- 3. TABLE: cafes
-- Curated KopiFinder cafes
-- ============================================================
CREATE TABLE IF NOT EXISTS public.cafes (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL CHECK (char_length(name) >= 2 AND char_length(name) <= 150),
  area                TEXT NOT NULL CHECK (area IN ('Jaksel', 'Jakpus', 'Jakbar', 'Jaktim', 'Jakut')),
  address             TEXT,
  lat                 DOUBLE PRECISION CHECK (lat BETWEEN -90 AND 90),
  lng                 DOUBLE PRECISION CHECK (lng BETWEEN -180 AND 180),
  price_min           INTEGER CHECK (price_min >= 0),
  price_max           INTEGER CHECK (price_max >= 0),
  hours               JSONB NOT NULL DEFAULT '{}',
  phone               TEXT,
  whatsapp            TEXT,
  website             TEXT,
  instagram           TEXT,
  facilities          TEXT[] NOT NULL DEFAULT '{}',
  photos              TEXT[] NOT NULL DEFAULT '{}',
  is_active           BOOLEAN NOT NULL DEFAULT FALSE,
  verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT check_price_range CHECK (price_max IS NULL OR price_min IS NULL OR price_max >= price_min)
);

-- ============================================================
-- 4. TABLE: cafe_place_links
-- Link between KopiFinder cafe and OSM place
-- ============================================================
CREATE TABLE IF NOT EXISTS public.cafe_place_links (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id       UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  osm_place_id  UUID NOT NULL REFERENCES public.osm_places(id) ON DELETE RESTRICT,
  match_method  TEXT NOT NULL CHECK (match_method IN ('manual', 'reviewed_import')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_cafe_osm_link UNIQUE (cafe_id, osm_place_id)
);

-- ============================================================
-- 5. TABLE: menus
-- Menu items for curated cafes
-- ============================================================
CREATE TABLE IF NOT EXISTS public.menus (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id     UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  name        TEXT NOT NULL CHECK (char_length(name) >= 1 AND char_length(name) <= 100),
  price       INTEGER NOT NULL CHECK (price >= 0),
  category    TEXT CHECK (category IN ('coffee', 'non-coffee', 'food', 'dessert')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 6. TABLE: reviews
-- Reviews written by users for curated cafes
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reviews (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  cafe_id     UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  text        TEXT CHECK (char_length(text) <= 1000),
  photo_url   TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_cafe_review UNIQUE (user_id, cafe_id)
);

-- ============================================================
-- 7. TABLE: saved_cafes
-- User saved/bookmarked cafes
-- ============================================================
CREATE TABLE IF NOT EXISTS public.saved_cafes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  cafe_id     UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  saved_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_saved_cafe UNIQUE (user_id, cafe_id)
);

-- ============================================================
-- 8. TABLE: posts
-- Community posts tied to a cafe
-- ============================================================
CREATE TABLE IF NOT EXISTS public.posts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  cafe_id     UUID NOT NULL REFERENCES public.cafes(id) ON DELETE RESTRICT,
  caption     TEXT NOT NULL CHECK (char_length(caption) >= 1 AND char_length(caption) <= 500),
  photo_url   TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 9. TABLE: post_likes
-- Likes on community posts
-- ============================================================
CREATE TABLE IF NOT EXISTS public.post_likes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_post_like UNIQUE (post_id, user_id)
);

-- ============================================================
-- 10. TABLE: comments
-- Comments and replies on community posts
-- ============================================================
CREATE TABLE IF NOT EXISTS public.comments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  parent_id   UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  text        TEXT NOT NULL CHECK (char_length(text) >= 1 AND char_length(text) <= 500),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 11. TABLE: comment_likes
-- Likes on comments
-- ============================================================
CREATE TABLE IF NOT EXISTS public.comment_likes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id  UUID NOT NULL REFERENCES public.comments(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_comment_like UNIQUE (comment_id, user_id)
);

-- ============================================================
-- 12. TABLE: ai_recommendation_history
-- AI Recommendation request & result logs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.ai_recommendation_history (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  purpose     TEXT NOT NULL CHECK (purpose IN ('Work', 'Study', 'Date', 'Hangout', 'Casual')),
  budget      TEXT NOT NULL CHECK (budget IN ('<30k', '30k-60k', '>60k')),
  details     TEXT CHECK (char_length(details) <= 500),
  result      JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 13. TABLE: offers
-- Special offers for cafes managed by admin
-- ============================================================
CREATE TABLE IF NOT EXISTS public.offers (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id           UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  product_name      TEXT NOT NULL CHECK (char_length(product_name) >= 1 AND char_length(product_name) <= 100),
  photo_url         TEXT,
  original_price    INTEGER NOT NULL CHECK (original_price >= 0),
  discounted_price  INTEGER NOT NULL CHECK (discounted_price >= 0 AND discounted_price < original_price),
  start_date        DATE NOT NULL,
  end_date          DATE NOT NULL CHECK (end_date >= start_date),
  is_active         BOOLEAN NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 14. TABLE: sync_runs
-- Log of OpenStreetMap background sync runs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.sync_runs (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  started_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at        TIMESTAMPTZ,
  area               TEXT CHECK (area IN ('Jaksel', 'Jakpus', 'Jakbar', 'Jaktim', 'Jakut')),
  found_count        INTEGER NOT NULL DEFAULT 0 CHECK (found_count >= 0),
  inserted_count     INTEGER NOT NULL DEFAULT 0 CHECK (inserted_count >= 0),
  updated_count      INTEGER NOT NULL DEFAULT 0 CHECK (updated_count >= 0),
  marked_stale_count INTEGER NOT NULL DEFAULT 0 CHECK (marked_stale_count >= 0),
  status             TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'success', 'partial', 'failed')),
  error_message      TEXT
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_username_trgm ON public.users USING gin(username gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_osm_places_area_status ON public.osm_places(area, sync_status);
CREATE INDEX IF NOT EXISTS idx_osm_places_name_trgm ON public.osm_places USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_osm_places_latlng ON public.osm_places(lat, lng);

CREATE INDEX IF NOT EXISTS idx_cafes_filter ON public.cafes(area, is_active, verification_status);
CREATE INDEX IF NOT EXISTS idx_cafes_name_trgm ON public.cafes USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_cafes_latlng ON public.cafes(lat, lng);

CREATE INDEX IF NOT EXISTS idx_cafe_place_links_cafe ON public.cafe_place_links(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_place_links_osm ON public.cafe_place_links(osm_place_id);

CREATE INDEX IF NOT EXISTS idx_menus_cafe ON public.menus(cafe_id);
CREATE INDEX IF NOT EXISTS idx_reviews_cafe_created ON public.reviews(cafe_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON public.reviews(user_id);

CREATE INDEX IF NOT EXISTS idx_saved_cafes_user ON public.saved_cafes(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_user ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_cafe ON public.posts(cafe_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON public.posts(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_post_likes_post ON public.post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user ON public.post_likes(user_id);

CREATE INDEX IF NOT EXISTS idx_comments_post ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user ON public.comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON public.comments(parent_id);

CREATE INDEX IF NOT EXISTS idx_comment_likes_comment ON public.comment_likes(comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_likes_user ON public.comment_likes(user_id);

CREATE INDEX IF NOT EXISTS idx_ai_history_user_created ON public.ai_recommendation_history(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_offers_active_dates ON public.offers(is_active, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_sync_runs_status ON public.sync_runs(status, started_at DESC);

-- ============================================================
-- TRIGGERS & FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_osm_places_updated_at BEFORE UPDATE ON public.osm_places FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_cafes_updated_at BEFORE UPDATE ON public.cafes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_reviews_updated_at BEFORE UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_posts_updated_at BEFORE UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_comments_updated_at BEFORE UPDATE ON public.comments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_offers_updated_at BEFORE UPDATE ON public.offers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  raw_username TEXT;
  clean_username TEXT;
  raw_name TEXT;
BEGIN
  raw_username := COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1));
  clean_username := regexp_replace(raw_username, '[^a-zA-Z0-9_]', '', 'g');
  IF char_length(clean_username) < 3 THEN
    clean_username := 'user_' || substr(md5(random()::text), 1, 8);
  END IF;
  raw_name := COALESCE(NEW.raw_user_meta_data->>'name', raw_username);

  INSERT INTO public.users (id, name, username, email, avatar_url)
  VALUES (
    NEW.id,
    raw_name,
    clean_username,
    NEW.email,
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.osm_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_place_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_cafes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recommendation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_runs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Public can view active osm places" ON public.osm_places;
CREATE POLICY "Public can view active osm places" ON public.osm_places FOR SELECT USING (sync_status = 'active');

DROP POLICY IF EXISTS "Public can view verified cafes" ON public.cafes;
CREATE POLICY "Public can view verified cafes" ON public.cafes FOR SELECT USING (is_active = true AND verification_status = 'verified');

DROP POLICY IF EXISTS "Public can view cafe place links" ON public.cafe_place_links;
CREATE POLICY "Public can view cafe place links" ON public.cafe_place_links FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.cafes WHERE cafes.id = cafe_place_links.cafe_id AND cafes.is_active = true AND cafes.verification_status = 'verified')
);

DROP POLICY IF EXISTS "Public can view cafe menus" ON public.menus;
CREATE POLICY "Public can view cafe menus" ON public.menus FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.cafes WHERE cafes.id = menus.cafe_id AND cafes.is_active = true AND cafes.verification_status = 'verified')
);

DROP POLICY IF EXISTS "Public can view reviews" ON public.reviews;
CREATE POLICY "Public can view reviews" ON public.reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own review" ON public.reviews;
CREATE POLICY "Users can insert own review" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own review" ON public.reviews;
CREATE POLICY "Users can update own review" ON public.reviews FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own review" ON public.reviews;
CREATE POLICY "Users can delete own review" ON public.reviews FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own saved cafes" ON public.saved_cafes;
CREATE POLICY "Users can view own saved cafes" ON public.saved_cafes FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own saved cafe" ON public.saved_cafes;
CREATE POLICY "Users can insert own saved cafe" ON public.saved_cafes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own saved cafe" ON public.saved_cafes;
CREATE POLICY "Users can delete own saved cafe" ON public.saved_cafes FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public can view posts" ON public.posts;
CREATE POLICY "Public can view posts" ON public.posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own post" ON public.posts;
CREATE POLICY "Users can insert own post" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own post" ON public.posts;
CREATE POLICY "Users can update own post" ON public.posts FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own post" ON public.posts;
CREATE POLICY "Users can delete own post" ON public.posts FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public can view post likes" ON public.post_likes;
CREATE POLICY "Public can view post likes" ON public.post_likes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own post like" ON public.post_likes;
CREATE POLICY "Users can insert own post like" ON public.post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own post like" ON public.post_likes;
CREATE POLICY "Users can delete own post like" ON public.post_likes FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public can view comments" ON public.comments;
CREATE POLICY "Public can view comments" ON public.comments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own comment" ON public.comments;
CREATE POLICY "Users can insert own comment" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own comment" ON public.comments;
CREATE POLICY "Users can update own comment" ON public.comments FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own comment" ON public.comments;
CREATE POLICY "Users can delete own comment" ON public.comments FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public can view comment likes" ON public.comment_likes;
CREATE POLICY "Public can view comment likes" ON public.comment_likes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own comment like" ON public.comment_likes;
CREATE POLICY "Users can insert own comment like" ON public.comment_likes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own comment like" ON public.comment_likes;
CREATE POLICY "Users can delete own comment like" ON public.comment_likes FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own AI history" ON public.ai_recommendation_history;
CREATE POLICY "Users can view own AI history" ON public.ai_recommendation_history FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own AI history" ON public.ai_recommendation_history;
CREATE POLICY "Users can insert own AI history" ON public.ai_recommendation_history FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own AI history" ON public.ai_recommendation_history;
CREATE POLICY "Users can delete own AI history" ON public.ai_recommendation_history FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public can view active offers" ON public.offers;
CREATE POLICY "Public can view active offers" ON public.offers FOR SELECT USING (
  is_active = true AND CURRENT_DATE >= start_date AND CURRENT_DATE <= end_date
);

-- ============================================================
-- STORAGE BUCKETS & STORAGE POLICIES
-- ============================================================
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

DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;
CREATE POLICY "Public can view avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'avatars' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar" ON storage.objects FOR UPDATE USING (
  bucket_id = 'avatars' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar" ON storage.objects FOR DELETE USING (
  bucket_id = 'avatars' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Public can view review photos" ON storage.objects;
CREATE POLICY "Public can view review photos" ON storage.objects FOR SELECT USING (bucket_id = 'review-photos');

DROP POLICY IF EXISTS "Users can upload own review photo" ON storage.objects;
CREATE POLICY "Users can upload own review photo" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'review-photos' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can delete own review photo" ON storage.objects;
CREATE POLICY "Users can delete own review photo" ON storage.objects FOR DELETE USING (
  bucket_id = 'review-photos' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Public can view post photos" ON storage.objects;
CREATE POLICY "Public can view post photos" ON storage.objects FOR SELECT USING (bucket_id = 'post-photos');

DROP POLICY IF EXISTS "Users can upload own post photo" ON storage.objects;
CREATE POLICY "Users can upload own post photo" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'post-photos' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can delete own post photo" ON storage.objects;
CREATE POLICY "Users can delete own post photo" ON storage.objects FOR DELETE USING (
  bucket_id = 'post-photos' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Public can view cafe photos" ON storage.objects;
CREATE POLICY "Public can view cafe photos" ON storage.objects FOR SELECT USING (bucket_id = 'cafe-photos');

DROP POLICY IF EXISTS "Public can view offer photos" ON storage.objects;
CREATE POLICY "Public can view offer photos" ON storage.objects FOR SELECT USING (bucket_id = 'offer-photos');
