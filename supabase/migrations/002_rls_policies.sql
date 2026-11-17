-- ============================================================
-- KopiFinder — Migration 002: Row Level Security (RLS) Policies
-- Target: Supabase PostgreSQL
-- ============================================================

-- Enable RLS on ALL tables in schema public (Default DENY)
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

-- ============================================================
-- 1. POLICIES: users
-- Users can only SELECT and UPDATE their own profile
-- ============================================================
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ============================================================
-- 2. POLICIES: osm_places
-- Public can SELECT active OSM places; mutations backend service-role only
-- ============================================================
DROP POLICY IF EXISTS "Public can view active osm places" ON public.osm_places;
CREATE POLICY "Public can view active osm places"
  ON public.osm_places FOR SELECT
  USING (sync_status = 'active');

-- ============================================================
-- 3. POLICIES: cafes
-- Public can SELECT active & verified cafes; mutations backend admin/service-role only
-- ============================================================
DROP POLICY IF EXISTS "Public can view verified cafes" ON public.cafes;
CREATE POLICY "Public can view verified cafes"
  ON public.cafes FOR SELECT
  USING (is_active = true AND verification_status = 'verified');

-- ============================================================
-- 4. POLICIES: cafe_place_links
-- Public can SELECT links for verified cafes
-- ============================================================
DROP POLICY IF EXISTS "Public can view cafe place links" ON public.cafe_place_links;
CREATE POLICY "Public can view cafe place links"
  ON public.cafe_place_links FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.cafes
      WHERE cafes.id = cafe_place_links.cafe_id
        AND cafes.is_active = true
        AND cafes.verification_status = 'verified'
    )
  );

-- ============================================================
-- 5. POLICIES: menus
-- Public can SELECT menu items for active & verified cafes
-- ============================================================
DROP POLICY IF EXISTS "Public can view cafe menus" ON public.menus;
CREATE POLICY "Public can view cafe menus"
  ON public.menus FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.cafes
      WHERE cafes.id = menus.cafe_id
        AND cafes.is_active = true
        AND cafes.verification_status = 'verified'
    )
  );

-- ============================================================
-- 6. POLICIES: reviews
-- Public SELECT; Authenticated user can INSERT/UPDATE/DELETE own review
-- ============================================================
DROP POLICY IF EXISTS "Public can view reviews" ON public.reviews;
CREATE POLICY "Public can view reviews"
  ON public.reviews FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert own review" ON public.reviews;
CREATE POLICY "Users can insert own review"
  ON public.reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own review" ON public.reviews;
CREATE POLICY "Users can update own review"
  ON public.reviews FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own review" ON public.reviews;
CREATE POLICY "Users can delete own review"
  ON public.reviews FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 7. POLICIES: saved_cafes
-- User can SELECT/INSERT/DELETE own bookmarks
-- ============================================================
DROP POLICY IF EXISTS "Users can view own saved cafes" ON public.saved_cafes;
CREATE POLICY "Users can view own saved cafes"
  ON public.saved_cafes FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own saved cafe" ON public.saved_cafes;
CREATE POLICY "Users can insert own saved cafe"
  ON public.saved_cafes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own saved cafe" ON public.saved_cafes;
CREATE POLICY "Users can delete own saved cafe"
  ON public.saved_cafes FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 8. POLICIES: posts
-- Public SELECT; Authenticated user can INSERT/UPDATE/DELETE own posts
-- ============================================================
DROP POLICY IF EXISTS "Public can view posts" ON public.posts;
CREATE POLICY "Public can view posts"
  ON public.posts FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert own post" ON public.posts;
CREATE POLICY "Users can insert own post"
  ON public.posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own post" ON public.posts;
CREATE POLICY "Users can update own post"
  ON public.posts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own post" ON public.posts;
CREATE POLICY "Users can delete own post"
  ON public.posts FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 9. POLICIES: post_likes
-- Public SELECT; Authenticated user can INSERT/DELETE own likes
-- ============================================================
DROP POLICY IF EXISTS "Public can view post likes" ON public.post_likes;
CREATE POLICY "Public can view post likes"
  ON public.post_likes FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert own post like" ON public.post_likes;
CREATE POLICY "Users can insert own post like"
  ON public.post_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own post like" ON public.post_likes;
CREATE POLICY "Users can delete own post like"
  ON public.post_likes FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 10. POLICIES: comments
-- Public SELECT; Authenticated user can INSERT/UPDATE/DELETE own comments
-- ============================================================
DROP POLICY IF EXISTS "Public can view comments" ON public.comments;
CREATE POLICY "Public can view comments"
  ON public.comments FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert own comment" ON public.comments;
CREATE POLICY "Users can insert own comment"
  ON public.comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own comment" ON public.comments;
CREATE POLICY "Users can update own comment"
  ON public.comments FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own comment" ON public.comments;
CREATE POLICY "Users can delete own comment"
  ON public.comments FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 11. POLICIES: comment_likes
-- Public SELECT; Authenticated user can INSERT/DELETE own comment likes
-- ============================================================
DROP POLICY IF EXISTS "Public can view comment likes" ON public.comment_likes;
CREATE POLICY "Public can view comment likes"
  ON public.comment_likes FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert own comment like" ON public.comment_likes;
CREATE POLICY "Users can insert own comment like"
  ON public.comment_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own comment like" ON public.comment_likes;
CREATE POLICY "Users can delete own comment like"
  ON public.comment_likes FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 12. POLICIES: ai_recommendation_history
-- User can SELECT/INSERT/DELETE own recommendation history
-- ============================================================
DROP POLICY IF EXISTS "Users can view own AI history" ON public.ai_recommendation_history;
CREATE POLICY "Users can view own AI history"
  ON public.ai_recommendation_history FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own AI history" ON public.ai_recommendation_history;
CREATE POLICY "Users can insert own AI history"
  ON public.ai_recommendation_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own AI history" ON public.ai_recommendation_history;
CREATE POLICY "Users can delete own AI history"
  ON public.ai_recommendation_history FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 13. POLICIES: offers
-- Public can SELECT active offers within valid date range
-- ============================================================
DROP POLICY IF EXISTS "Public can view active offers" ON public.offers;
CREATE POLICY "Public can view active offers"
  ON public.offers FOR SELECT
  USING (
    is_active = true
    AND CURRENT_DATE >= start_date
    AND CURRENT_DATE <= end_date
  );
