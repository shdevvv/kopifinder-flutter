-- ============================================================
-- KopiFinder — Complete Database Migration
-- File: migrations/001_initial_schema.sql
-- Target: Supabase PostgreSQL
-- Run via: Supabase SQL Editor → New Query
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- for text search

-- ============================================================
-- TABLE: users
-- Synced with Supabase Auth (auth.users)
-- ============================================================

CREATE TABLE public.users (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL CHECK (char_length(name) >= 2 AND char_length(name) <= 100),
  username        TEXT NOT NULL UNIQUE CHECK (
                    char_length(username) >= 3 AND
                    char_length(username) <= 30 AND
                    username ~ '^[a-zA-Z0-9_]+$'
                  ),
  email           TEXT NOT NULL UNIQUE,
  avatar_url      TEXT,
  location        TEXT CHECK (char_length(location) <= 100),
  cafes_visited   INT NOT NULL DEFAULT 0 CHECK (cafes_visited >= 0),
  reviews_count   INT NOT NULL DEFAULT 0 CHECK (reviews_count >= 0),
  posts_count     INT NOT NULL DEFAULT 0 CHECK (posts_count >= 0),
  saved_count     INT NOT NULL DEFAULT 0 CHECK (saved_count >= 0),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for username search
CREATE INDEX idx_users_username ON public.users(username);
CREATE INDEX idx_users_username_trgm ON public.users USING gin(username gin_trgm_ops);

-- ============================================================
-- TABLE: cafes
-- ============================================================

CREATE TABLE public.cafes (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL CHECK (char_length(name) >= 2 AND char_length(name) <= 150),
  area            TEXT NOT NULL CHECK (area IN ('Jaksel', 'Jakpus', 'Jakbar', 'Jaktim', 'Jakut')),
  address         TEXT NOT NULL,
  description     TEXT,
  lat             DOUBLE PRECISION NOT NULL CHECK (lat BETWEEN -90 AND 90),
  lng             DOUBLE PRECISION NOT NULL CHECK (lng BETWEEN -180 AND 180),
  rating          NUMERIC(2,1) CHECK (rating BETWEEN 1.0 AND 5.0),
  price_min       INT NOT NULL CHECK (price_min >= 0),
  price_max       INT NOT NULL CHECK (price_max >= price_min),
  hours           JSONB NOT NULL DEFAULT '{}',
  -- hours format: {"monday":"07:00-22:00","tuesday":"07:00-22:00",...,"sunday":"closed"}
  phone           TEXT,
  whatsapp        TEXT,
  instagram       TEXT,
  website         TEXT,
  facilities      TEXT[] NOT NULL DEFAULT '{}',
  -- facilities values: 'WiFi', 'AC', 'Parking', 'Indoor', 'Outdoor', 'Pet Friendly', 'Musholla', 'Smoking Area', 'Power Outlet', 'Laptop Friendly'
  photos          TEXT[] NOT NULL DEFAULT '{}',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_cafes_area ON public.cafes(area);
CREATE INDEX idx_cafes_is_active ON public.cafes(is_active);
CREATE INDEX idx_cafes_rating ON public.cafes(rating DESC);
CREATE INDEX idx_cafes_price_min ON public.cafes(price_min);
CREATE INDEX idx_cafes_name_trgm ON public.cafes USING gin(name gin_trgm_ops);
-- Spatial-like index (without PostGIS, use composite)
CREATE INDEX idx_cafes_latlng ON public.cafes(lat, lng);

-- ============================================================
-- TABLE: menus
-- ============================================================

CREATE TABLE public.menus (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cafe_id     UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  name        TEXT NOT NULL CHECK (char_length(name) >= 1 AND char_length(name) <= 100),
  price       INT NOT NULL CHECK (price >= 0),
  category    TEXT NOT NULL CHECK (category IN ('coffee', 'non-coffee', 'food', 'dessert')),
  description TEXT,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_menus_cafe_id ON public.menus(cafe_id);
CREATE INDEX idx_menus_category ON public.menus(category);

-- ============================================================
-- TABLE: reviews
-- ============================================================

CREATE TABLE public.reviews (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  cafe_id     UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  text        TEXT NOT NULL CHECK (char_length(text) >= 10 AND char_length(text) <= 1000),
  photo_url   TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Each user can only review a cafe once
  CONSTRAINT unique_user_cafe_review UNIQUE (user_id, cafe_id)
);

CREATE INDEX idx_reviews_cafe_id ON public.reviews(cafe_id);
CREATE INDEX idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX idx_reviews_created_at ON public.reviews(created_at DESC);

-- ============================================================
-- TABLE: saved_cafes
-- ============================================================

CREATE TABLE public.saved_cafes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  cafe_id     UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  saved_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- No duplicate bookmarks
  CONSTRAINT unique_user_saved_cafe UNIQUE (user_id, cafe_id)
);

CREATE INDEX idx_saved_cafes_user_id ON public.saved_cafes(user_id);
CREATE INDEX idx_saved_cafes_saved_at ON public.saved_cafes(saved_at DESC);

-- ============================================================
-- TABLE: posts (Community)
-- ============================================================

CREATE TABLE public.posts (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  cafe_id     UUID NOT NULL REFERENCES public.cafes(id) ON DELETE SET NULL,
  caption     TEXT NOT NULL CHECK (char_length(caption) >= 1 AND char_length(caption) <= 500),
  photo_url   TEXT,
  likes_count INT NOT NULL DEFAULT 0 CHECK (likes_count >= 0),
  comments_count INT NOT NULL DEFAULT 0 CHECK (comments_count >= 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_posts_cafe_id ON public.posts(cafe_id);
CREATE INDEX idx_posts_likes_count ON public.posts(likes_count DESC);
CREATE INDEX idx_posts_created_at ON public.posts(created_at DESC);

-- ============================================================
-- TABLE: post_likes
-- ============================================================

CREATE TABLE public.post_likes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id     UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- No duplicate likes
  CONSTRAINT unique_post_like UNIQUE (post_id, user_id)
);

CREATE INDEX idx_post_likes_post_id ON public.post_likes(post_id);
CREATE INDEX idx_post_likes_user_id ON public.post_likes(user_id);

-- ============================================================
-- TABLE: comments
-- ============================================================

CREATE TABLE public.comments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id     UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  parent_id   UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  -- parent_id = NULL means top-level comment, NOT NULL means reply
  text        TEXT NOT NULL CHECK (char_length(text) >= 1 AND char_length(text) <= 500),
  likes_count INT NOT NULL DEFAULT 0 CHECK (likes_count >= 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_comments_post_id ON public.comments(post_id);
CREATE INDEX idx_comments_user_id ON public.comments(user_id);
CREATE INDEX idx_comments_parent_id ON public.comments(parent_id);
CREATE INDEX idx_comments_created_at ON public.comments(created_at DESC);

-- ============================================================
-- TABLE: comment_likes (ADDED — required by Community features)
-- ============================================================

CREATE TABLE public.comment_likes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  comment_id  UUID NOT NULL REFERENCES public.comments(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- No duplicate likes
  CONSTRAINT unique_comment_like UNIQUE (comment_id, user_id)
);

CREATE INDEX idx_comment_likes_comment_id ON public.comment_likes(comment_id);
CREATE INDEX idx_comment_likes_user_id ON public.comment_likes(user_id);

-- ============================================================
-- TABLE: ai_recommendation_history
-- ============================================================

CREATE TABLE public.ai_recommendation_history (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  purpose     TEXT NOT NULL CHECK (purpose IN ('Work', 'Study', 'Date', 'Hangout', 'Casual')),
  budget      TEXT NOT NULL CHECK (budget IN ('<30k', '30k-60k', '>60k')),
  details     TEXT CHECK (char_length(details) <= 500),
  result      JSONB NOT NULL DEFAULT '[]',
  -- result format: [{"cafe_id":"uuid","match_percentage":98,"reason":"...","matched_preferences":["..."]}]
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_history_user_id ON public.ai_recommendation_history(user_id);
CREATE INDEX idx_ai_history_created_at ON public.ai_recommendation_history(created_at DESC);

-- ============================================================
-- TABLE: offers (Special Offers — admin-managed)
-- ============================================================

CREATE TABLE public.offers (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cafe_id           UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  product_name      TEXT NOT NULL CHECK (char_length(product_name) >= 1 AND char_length(product_name) <= 100),
  photo_url         TEXT,
  original_price    INT NOT NULL CHECK (original_price > 0),
  discounted_price  INT NOT NULL CHECK (discounted_price > 0 AND discounted_price < original_price),
  start_date        DATE NOT NULL,
  end_date          DATE NOT NULL CHECK (end_date >= start_date),
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_offers_cafe_id ON public.offers(cafe_id);
CREATE INDEX idx_offers_is_active ON public.offers(is_active);
CREATE INDEX idx_offers_end_date ON public.offers(end_date);

-- ============================================================
-- TRIGGERS: auto-update timestamps
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cafes_updated_at BEFORE UPDATE ON public.cafes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offers_updated_at BEFORE UPDATE ON public.offers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TRIGGERS: sync counters
-- ============================================================

-- Auto-increment/decrement posts.likes_count
CREATE OR REPLACE FUNCTION sync_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_post_likes
  AFTER INSERT OR DELETE ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION sync_post_likes_count();

-- Auto-increment/decrement comments.likes_count
CREATE OR REPLACE FUNCTION sync_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.comments SET likes_count = likes_count + 1 WHERE id = NEW.comment_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.comments SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.comment_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_comment_likes
  AFTER INSERT OR DELETE ON public.comment_likes
  FOR EACH ROW EXECUTE FUNCTION sync_comment_likes_count();

-- Auto-increment/decrement posts.comments_count
CREATE OR REPLACE FUNCTION sync_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.parent_id IS NULL THEN
    UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' AND OLD.parent_id IS NULL THEN
    UPDATE public.posts SET comments_count = GREATEST(0, comments_count - 1) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_post_comments
  AFTER INSERT OR DELETE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION sync_post_comments_count();

-- Auto-update users.reviews_count
CREATE OR REPLACE FUNCTION sync_user_reviews_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.users SET
      reviews_count = reviews_count + 1,
      cafes_visited = cafes_visited + 1
    WHERE id = NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.users SET
      reviews_count = GREATEST(0, reviews_count - 1),
      cafes_visited = GREATEST(0, cafes_visited - 1)
    WHERE id = OLD.user_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_reviews_count
  AFTER INSERT OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION sync_user_reviews_count();

-- Auto-update users.posts_count
CREATE OR REPLACE FUNCTION sync_user_posts_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.users SET posts_count = posts_count + 1 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.users SET posts_count = GREATEST(0, posts_count - 1) WHERE id = OLD.user_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_posts_count
  AFTER INSERT OR DELETE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION sync_user_posts_count();

-- Auto-update users.saved_count
CREATE OR REPLACE FUNCTION sync_user_saved_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.users SET saved_count = saved_count + 1 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.users SET saved_count = GREATEST(0, saved_count - 1) WHERE id = OLD.user_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_saved_count
  AFTER INSERT OR DELETE ON public.saved_cafes
  FOR EACH ROW EXECUTE FUNCTION sync_user_saved_count();

-- ============================================================
-- TRIGGER: sync user profile from Supabase Auth on signup
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, username)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'KopiFinder User'),
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_cafes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recommendation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;

-- ---- users ----
CREATE POLICY "Users can view all profiles" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can delete own account" ON public.users FOR DELETE USING (auth.uid() = id);

-- ---- cafes (read-only for users, write for service role only) ----
CREATE POLICY "Anyone can view active cafes" ON public.cafes FOR SELECT USING (is_active = true);
-- INSERT/UPDATE/DELETE only via service role (backend) — no policy = denied for anon/user

-- ---- menus ----
CREATE POLICY "Anyone can view menus" ON public.menus FOR SELECT USING (true);

-- ---- reviews ----
CREATE POLICY "Anyone can read reviews" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Auth users can create reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own reviews" ON public.reviews FOR DELETE USING (auth.uid() = user_id);

-- ---- saved_cafes ----
CREATE POLICY "Users can view own saved cafes" ON public.saved_cafes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can save cafes" ON public.saved_cafes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unsave cafes" ON public.saved_cafes FOR DELETE USING (auth.uid() = user_id);

-- ---- posts ----
CREATE POLICY "Anyone can read posts" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Auth users can create posts" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON public.posts FOR DELETE USING (auth.uid() = user_id);

-- ---- post_likes ----
CREATE POLICY "Anyone can view likes" ON public.post_likes FOR SELECT USING (true);
CREATE POLICY "Auth users can like" ON public.post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike own like" ON public.post_likes FOR DELETE USING (auth.uid() = user_id);

-- ---- comments ----
CREATE POLICY "Anyone can read comments" ON public.comments FOR SELECT USING (true);
CREATE POLICY "Auth users can create comments" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON public.comments FOR DELETE USING (auth.uid() = user_id);

-- ---- comment_likes ----
CREATE POLICY "Anyone can view comment likes" ON public.comment_likes FOR SELECT USING (true);
CREATE POLICY "Auth users can like comments" ON public.comment_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike own comment like" ON public.comment_likes FOR DELETE USING (auth.uid() = user_id);

-- ---- ai_recommendation_history ----
CREATE POLICY "Users can view own AI history" ON public.ai_recommendation_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Backend inserts AI history" ON public.ai_recommendation_history FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ---- offers ----
CREATE POLICY "Anyone can view active offers" ON public.offers FOR SELECT USING (is_active = true AND end_date >= CURRENT_DATE);
-- INSERT/UPDATE/DELETE only via service role (admin/backend)

-- ============================================================
-- DATABASE FUNCTION: check username availability
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_username_available(check_username TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN NOT EXISTS (SELECT 1 FROM public.users WHERE username = check_username);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- DATABASE FUNCTION: get cafe with distance from user location
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_cafes_with_distance(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  area TEXT,
  address TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  rating NUMERIC,
  price_min INT,
  price_max INT,
  facilities TEXT[],
  photos TEXT[],
  hours JSONB,
  phone TEXT,
  whatsapp TEXT,
  instagram TEXT,
  distance_km DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id, c.name, c.area, c.address, c.lat, c.lng,
    c.rating, c.price_min, c.price_max, c.facilities, c.photos, c.hours,
    c.phone, c.whatsapp, c.instagram,
    -- Haversine formula approximation
    (6371 * acos(
      LEAST(1.0, cos(radians(user_lat)) * cos(radians(c.lat)) *
      cos(radians(c.lng) - radians(user_lng)) +
      sin(radians(user_lat)) * sin(radians(c.lat)))
    )) AS distance_km
  FROM public.cafes c
  WHERE c.is_active = true
  ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

