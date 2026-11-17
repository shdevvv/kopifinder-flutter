# PHASE 2 — DATABASE & SECURITY COMPLETION REPORT
**Project:** KopiFinder  
**Phase:** Phase 2 (Database Schema v2.0, RLS Policies, Storage Setup & Security Audit)  
**Date:** November 17, 2026  
**Status:** COMPLETE (PASS)  

---

## 1. Status Phase 2
- **Status Akhir Phase 2**: `PASS` (Skema database v2.0, RLS Policies, Storage Policies, Triggers, dan Indexes telah selesai dibuat dan diverifikasi).
- **Kesiapan Phase 3**: `READY` (Siap dilanjutkan ke Phase 3 — OpenStreetMap Ingestion Pipeline).

---

## 2. Ringkasan Pekerjaan yang Diselesaikan

1. **Penyusunan Skema Database v2.0 Modular & Idempoten**:
   - Dibuat file migration SQL `001_initial_schema.sql` pada `supabase/migrations/`.
   - Mengisi 14 tabel publik dengan tipe data, constraint CHECK, foreign keys, dan trigger otomatis.
   - Dibuat fungsi trigger `handle_new_user()` yang secara otomatis membuat profil pengguna pada `public.users` saat pendaftaran Supabase Auth (`auth.users`).
   - Dibuat fungsi trigger `update_updated_at_column()` untuk menjaga timestamp pembaruan data secara otomatis.

2. **Penerapan Row Level Security (RLS) Denial by Default**:
   - Dibuat file migration SQL `002_rls_policies.sql`.
   - Mengaktifkan `ENABLE ROW LEVEL SECURITY` pada seluruh 14 tabel publik (`users`, `osm_places`, `cafes`, `cafe_place_links`, `menus`, `reviews`, `saved_cafes`, `posts`, `post_likes`, `comments`, `comment_likes`, `ai_recommendation_history`, `offers`, `sync_runs`).
   - Menyusun kebijakan RLS khusus untuk `SELECT`, `INSERT`, `UPDATE`, dan `DELETE` berbasis `auth.uid()`.
   - Memastikan data sensitif pengguna (profil privat, bookmark, history AI) hanya dapat diakses oleh pemiliknya.

3. **Konfigurasi Supabase Storage & Storage Policies**:
   - Dibuat file migration SQL `003_storage_policies.sql`.
   - Mendefinisikan 5 bucket storage: `avatars`, `review-photos`, `post-photos`, `cafe-photos`, `offer-photos`.
   - Membatasi ukuran file dan MIME type gambar (`image/jpeg`, `image/png`, `image/webp`).
   - Menerapkan kebijakan storage RLS agar pengguna terautentikasi hanya dapat mengunggah/mengubah/menghapus file pada folder miliknya sendiri (`{bucket}/{user_id}/*`).

4. **KONSOLIDASI FILE SCHEMAS & AUTOMATED TESTING**:
   - Memperbarui file utama `database_schema.sql` pada root proyek agar berisi gabungan script siap pakai untuk Supabase SQL Editor.
   - Dibuat unit test otomatis `kopifinder-backend/tests/migration.test.ts` untuk memverifikasi keutuhan 14 tabel, RLS policies, dan storage buckets.

---

## 3. Daftar Tabel & Relasi Database yang Dibuat

| # | Nama Tabel | Fungsi / Deskripsi | Foreign Keys & Constraints |
|---|---|---|---|
| 1 | `users` | Profil pengguna terhubung ke Auth | `id` → `auth.users(id) ON DELETE CASCADE`. Constraint username regex & unique. |
| 2 | `osm_places` | Katalog raw tempat OpenStreetMap | `unique(osm_type, osm_id)`, check lat/lng, check `sync_status`. |
| 3 | `cafes` | Entitas kafe KopiFinder terkurasi | Check `price_max >= price_min`, check `verification_status`. |
| 4 | `cafe_place_links` | Relasi kafe KopiFinder ↔ OSM place | `cafe_id` → `cafes(id)`, `osm_place_id` → `osm_places(id)`. Unique pair. |
| 5 | `menus` | Item menu kafe KopiFinder | `cafe_id` → `cafes(id) ON DELETE CASCADE`. Check `price >= 0`. |
| 6 | `reviews` | Ulasan kafe oleh pengguna | `user_id` → `users(id)`, `cafe_id` → `cafes(id)`. `unique(user_id, cafe_id)`. Check rating 1–5. |
| 7 | `saved_cafes` | Bookmark kafe pengguna | `user_id` → `users(id)`, `cafe_id` → `cafes(id)`. `unique(user_id, cafe_id)`. |
| 8 | `posts` | Postingan komunitas kafe | `user_id` → `users(id)`, `cafe_id` → `cafes(id) ON DELETE RESTRICT`. |
| 9 | `post_likes` | Like pada postingan komunitas | `post_id` → `posts(id)`, `user_id` → `users(id)`. Unique pair. |
| 10 | `comments` | Komentar & balasan komentar | `post_id` → `posts(id)`, `user_id` → `users(id)`, `parent_id` → `comments(id)`. |
| 11 | `comment_likes` | Like pada komentar | `comment_id` → `comments(id)`, `user_id` → `users(id)`. Unique pair. |
| 12 | `ai_recommendation_history` | Riwayat rekomendasi AI | `user_id` → `users(id)`. Check purpose & budget. |
| 13 | `offers` | Promo/Diskon kafe | `cafe_id` → `cafes(id)`. Check `discounted_price < original_price` & `end_date >= start_date`. |
| 14 | `sync_runs` | Log sinkronisasi background OSM | Check `found_count`, `inserted_count`, `updated_count`, `status`. |

---

## 4. Daftar File Migration yang Dibuat

1. `supabase/migrations/001_initial_schema.sql`: Pembuatan 14 tabel, index, check constraints, dan trigger `handle_new_user`.
2. `supabase/migrations/002_rls_policies.sql`: Pengaktifan RLS pada 14 tabel dan penyusunan kebijakan RLS per operasi (SELECT, INSERT, UPDATE, DELETE).
3. `supabase/migrations/003_storage_policies.sql`: Pendaftaran 5 bucket storage dan kebijakan RLS folder storage per user.
4. `database_schema.sql` (Root Project): Master script konsolidasi v2.0 yang dapat dijalankan langsung di Supabase SQL Editor.
5. `kopifinder-backend/tests/migration.test.ts`: Skrip pengujian otomatis keutuhan file migrasi.

---

## 5. Hasil Pengujian & Verifikasi

### Pengujian 1: Verifikasi Keutuhan Skema SQL v2.0
- **Tools**: Jest Automated Test Suite (`npm run test`)
- **Langkah Pengujian**: Menjalankan pengujian otomatis untuk memverifikasi bahwa seluruh 14 tabel, RLS policies, dan storage buckets telah terdefinisi dalam file migration SQL.
- **Hasil yang Diharapkan**: Seluruh assertion test bernilai `true`.
- **Hasil Aktual**: `Test Suites: 2 passed, 2 total. Tests: 6 passed, 6 total.` Exit code `0`.
- **Status**: `PASS`
- **Bukti Output Terminal**:
```text
 PASS  tests/migration.test.ts
  Database Migration Files Verification (v2.0)
    √ should have all 3 migration files present in supabase/migrations/ (8 ms)
    √ 001_initial_schema.sql should define all 14 required tables (3 ms)
    √ 002_rls_policies.sql should enable RLS on all 14 tables and define policies (3 ms)
    √ 003_storage_policies.sql should define all 5 storage buckets and storage RLS (2 ms)

 PASS  tests/health.test.ts
  GET /api/v1/health
    √ should return 200 OK with health status json payload (52 ms)
    √ should return 404 for unknown endpoints (7 ms)
```

### Pengujian 2: Verifikasi Kebijakan Row Level Security (RLS)
- **Tools**: Code Inspection & SQL Validation
- **Langkah Pengujian**: Memeriksa RLS statement pada `002_rls_policies.sql` untuk setiap konteks pengguna (Anon, Authenticated User, Owner, Service Role).
- **Hasil Pengujian RLS**:
  - `users`: User A hanya dapat membaca & mengubah baris miliknya sendiri (`auth.uid() = id`). Anon tidak mendapatkan akses. (`PASS`)
  - `saved_cafes` & `ai_recommendation_history`: Hanya pemilik data yang dapat membaca, menambah, dan menghapus (`auth.uid() = user_id`). (`PASS`)
  - `reviews`, `posts`, `comments`: Publik dapat membaca (`SELECT USING (true)`), namun hanya pemilik yang dapat menambah/mengubah/menghapus (`auth.uid() = user_id`). (`PASS`)
  - `cafes`, `osm_places`, `offers`: Publik hanya dapat membaca data yang aktif dan terverifikasi (`is_active = true AND verification_status = 'verified'`). Penulisan/pengubahan ditolak untuk publik & user biasa (hanya backend service-role). (`PASS`)
  - `sync_runs`: Tanpa kebijakan RLS publik; hanya dapat diakses melalui backend service-role. (`PASS`)
- **Status**: `PASS`

### Pengujian 3: Verifikasi Storage Buckets & Policies
- **Tools**: Code Inspection (`003_storage_policies.sql`)
- **Langkah Pengujian**: Memeriksa batasan MIME type, batasan ukuran file, dan isolasi folder per pengguna pada Supabase Storage.
- **Hasil Pengujian**:
  - `avatars`, `review-photos`, `post-photos`, `cafe-photos`, `offer-photos` terdaftar dengan `allowed_mime_types = ['image/jpeg', 'image/png', 'image/webp']`.
  - Ukuran file dibatasi 5MB (avatars) dan 10MB (photos).
  - Folder upload diisolasi: pengguna hanya dapat mengunggah ke folder ber-ID dirinya (`{bucket}/{auth.uid()}/*`).
- **Status**: `PASS`

---

## 6. Instruksi Jalankan Migration di Supabase Dashboard (User Action)

Untuk menerapkan skema database ini ke proyek Supabase Anda:
1. Buka [Supabase Dashboard](https://supabase.com/dashboard) dan pilih proyek KopiFinder Anda.
2. Buka menu **SQL Editor** pada sidebar kiri.
3. Klik **New query**.
4. Buka file `database_schema.sql` yang berada di root folder proyek ini, salin seluruh isinya, dan tempelkan pada SQL Editor.
5. Klik **Run** (atau tombol ▶).
6. Buka **Table Editor** untuk memverifikasi bahwa 14 tabel (`users`, `osm_places`, `cafes`, `cafe_place_links`, `menus`, `reviews`, `saved_cafes`, `posts`, `post_likes`, `comments`, `comment_likes`, `ai_recommendation_history`, `offers`, `sync_runs`) telah berhasil terbentuk beserta tanda gembok RLS.
7. Buka **Storage** untuk memverifikasi bahwa 5 bucket (`avatars`, `review-photos`, `post-photos`, `cafe-photos`, `offer-photos`) telah tersedia.

---

## 7. Status Checklist & Kriteria Keberhasilan Phase 2

| Checklist Item | Status | Keterangan |
|---|---|---|
| Pembuatan Skema Database 14 Tabel (v2.0) | `PASS` | Seluruh tabel, FK, UNIQUE, dan CHECK constraints sesuai `plan.md`. |
| Trigger Otomatis (`handle_new_user` & `updated_at`) | `PASS` | Pengguna baru dari Supabase Auth otomatis dibuatkan profil. |
| Row Level Security (RLS) Denial by Default | `PASS` | 14 tabel diaktifkan RLS dengan kebijakan akses berbasis `auth.uid()`. |
| Supabase Storage Buckets & Policies | `PASS` | 5 bucket dibuat dengan isolasi folder user dan MIME filter. |
| Master Migration File (`database_schema.sql`) | `PASS` | Konsolidasi v2.0 siap dijalankan di Supabase SQL Editor. |
| Automated Migration Unit Tests | `PASS` | 6/6 test cases lulus pada Jest testing suite. |

**Kriteria Keberhasilan Phase 2**: LULUS (`PASS`). Skema database v2.0, aturan RLS, dan Storage policies telah selesai disusun, dites, dan didokumentasikan.

---

## 8. Status Kesiapan Phase 3

Phase 2 telah memenuhi seluruh acceptance criteria. Proyek ini siap dilanjutkan ke **Phase 3 — OpenStreetMap (OSM) Ingestion Pipeline** setelah mendapatkan persetujuan Pemilik Proyek.
