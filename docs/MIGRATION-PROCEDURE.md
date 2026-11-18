# Database Migration Procedure — KopiFinder

Panduan langkah-demi-langkah untuk menjalankan migration schema database KopiFinder di Supabase.

## Lokasi File Migration

```
d:\IT\kopifinder\supabase\migrations\
├── 001_initial_schema.sql     # Tabel utama: users, cafes, menus, reviews, dll
├── 002_rls_policies.sql       # Row Level Security policies
└── 003_storage_policies.sql   # Storage bucket policies
```

---

## Cara Menjalankan Migration (via Supabase SQL Editor)

### Prasyarat
- Sudah memiliki Supabase project yang aktif
- Sudah login ke [https://supabase.com/dashboard](https://supabase.com/dashboard)

### Langkah 1 — Buka SQL Editor
1. Buka Supabase Dashboard → pilih project KopiFinder
2. Di sidebar kiri, klik **SQL Editor**
3. Klik **New Query**

### Langkah 2 — Jalankan `001_initial_schema.sql`
1. Buka file `supabase/migrations/001_initial_schema.sql` di text editor
2. Copy seluruh isinya
3. Paste ke SQL Editor Supabase
4. Klik **Run** (atau Ctrl+Enter)
5. Pastikan output: `Success. No rows returned`
6. Verifikasi di **Table Editor**: tabel-tabel berikut harus muncul:
   - `users`, `cafes`, `cafe_place_links`, `osm_places`
   - `menus`, `reviews`, `saved_cafes`
   - `posts`, `post_likes`, `comments`, `comment_likes`
   - `ai_recommendation_history`, `offers`, `sync_runs`

### Langkah 3 — Jalankan `002_rls_policies.sql`
1. Buka **New Query** baru di SQL Editor
2. Copy isi `supabase/migrations/002_rls_policies.sql`
3. Paste dan klik **Run**
4. Verifikasi: tidak ada error. RLS policies aktif di tabel-tabel utama.

### Langkah 4 — Jalankan `003_storage_policies.sql`
1. Buka **New Query** baru di SQL Editor
2. Copy isi `supabase/migrations/003_storage_policies.sql`
3. Paste dan klik **Run**
4. Verifikasi storage policies di **Storage → Policies**

---

## Verifikasi Setelah Migration

### Cek Tabel
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```
Harus menampilkan 14 tabel.

### Cek RLS Aktif
```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```
Kolom `rowsecurity` harus `true` untuk semua tabel utama.

### Cek Storage Buckets
Di Supabase Dashboard → **Storage**, pastikan ada 5 bucket:
- `cafe-photos`
- `menu-photos`
- `post-photos`
- `profile-photos`
- `review-photos`

---

## Reset Migration (Jika Perlu Ulang dari Awal)

> ⚠️ **PERINGATAN:** Ini akan menghapus seluruh data. Lakukan hanya di environment dev/staging.

```sql
-- Hapus semua tabel secara berurutan (reverse dependency order)
DROP TABLE IF EXISTS sync_runs CASCADE;
DROP TABLE IF EXISTS ai_recommendation_history CASCADE;
DROP TABLE IF EXISTS offers CASCADE;
DROP TABLE IF EXISTS comment_likes CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS saved_cafes CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS menus CASCADE;
DROP TABLE IF EXISTS cafe_place_links CASCADE;
DROP TABLE IF EXISTS osm_places CASCADE;
DROP TABLE IF EXISTS cafes CASCADE;
DROP TABLE IF EXISTS users CASCADE;
```

Setelah drop, ulangi dari Langkah 2.

---

## Urutan Dependency Foreign Key

```
auth.users (Supabase Auth — tidak perlu dibuat manual)
    └── users
            ├── cafes
            │   ├── cafe_place_links → osm_places
            │   ├── menus
            │   └── reviews ←── users
            ├── saved_cafes → cafes
            ├── posts
            │   ├── post_likes
            │   └── comments
            │       └── comment_likes
            ├── ai_recommendation_history
            └── sync_runs (tidak ada FK ke users)
```

---

*Dibuat untuk KopiFinder Phase 6 — Deployment Staging*
*Tanggal: 2026-11-18*
