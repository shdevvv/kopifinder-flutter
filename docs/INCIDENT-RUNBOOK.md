# Incident Runbook & Rollback Guide — KopiFinder

Panduan penanganan insiden produksi dan prosedur rollback untuk KopiFinder.

---

## A. Kategori Insiden

| Severity | Deskripsi | Target Respons |
|---|---|---|
| P1 — Critical | Aplikasi tidak bisa dibuka, auth down, data hilang | < 1 jam |
| P2 — High | Fitur utama tidak berfungsi (cafe tidak muncul, search error) | < 4 jam |
| P3 — Medium | Fitur sekunder bermasalah, UI glitch | < 24 jam |
| P4 — Low | Typo, informasi tidak akurat | < 1 minggu |

---

## B. Checklist Respons Insiden

### Langkah 1 — Identifikasi
- [ ] Cek Railway logs: Dashboard → Deployments → Logs
- [ ] Cek Supabase logs: Dashboard → Logs Explorer
- [ ] Reproduce masalah dengan akun test
- [ ] Tentukan severity (P1–P4)

### Langkah 2 — Isolasi
- [ ] Apakah masalah di backend (Railway) atau database (Supabase)?
- [ ] Apakah masalah di semua user atau sebagian?
- [ ] Apakah masalah dimulai setelah deployment tertentu?

### Langkah 3 — Mitigasi
- [ ] Jika P1: langsung rollback ke versi sebelumnya (lihat bagian C)
- [ ] Jika P2: apply hotfix atau disable fitur bermasalah
- [ ] Update status ke user jika insiden lebih dari 30 menit

### Langkah 4 — Resolusi
- [ ] Deploy fix
- [ ] Verifikasi masalah teratasi
- [ ] Monitor 30 menit setelah fix

### Langkah 5 — Post-mortem
- [ ] Tulis laporan insiden (what, when, impact, root cause, fix)
- [ ] Simpan di `docs/incidents/YYYY-MM-DD-incident.md`

---

## C. Rollback Procedures

### C1. Rollback Backend (Railway)

**Rollback deployment Railway:**
1. Buka Railway Dashboard → project KopiFinder → **Deployments**
2. Temukan deployment terakhir yang stabil (status: Success)
3. Klik **Rollback** di deployment tersebut
4. Konfirmasi rollback
5. Verifikasi: `curl https://[RAILWAY-URL]/api/v1/health/ready`

**Rollback via Railway CLI:**
```bash
railway login
railway status
# Lihat deployment IDs
railway deployments list
# Rollback ke deployment ID tertentu
railway rollback [DEPLOYMENT-ID]
```

---

### C2. Rollback Database (Supabase)

> ⚠️ **PERINGATAN:** Rollback database akan mempengaruhi SELURUH data. Backup dulu sebelum rollback.

**Langkah sebelum rollback:**
```bash
# Backup data terkini (jika masih bisa diakses)
pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  --format=custom \
  --no-acl --no-owner \
  --file="emergency_backup_$(date +%Y%m%d_%H%M%S).dump"
```

**Rollback ke backup otomatis Supabase:**
1. Supabase Dashboard → **Project Settings** → **Database** → **Backups**
2. Pilih tanggal backup yang diinginkan
3. Klik **Restore** → konfirmasi
4. Tunggu 5–15 menit
5. Verifikasi data: jalankan query COUNT pada tabel utama

**Rollback migration (undo migration terakhir):**
```sql
-- Jika migration terakhir menyebabkan masalah
-- Jalankan SQL kebalikan dari migration yang bermasalah
-- di Supabase SQL Editor
-- Contoh: jika migration menambah kolom, hapus kolom tersebut
ALTER TABLE cafes DROP COLUMN IF EXISTS new_column;
```

---

### C3. Rollback Flutter App

Karena aplikasi sudah terdistribusi via Google Play:

**Hentikan rollout (jika sedang staged rollout):**
1. Play Console → App → **Production** → Edit release
2. Klik **Halt rollout**

**Publish versi sebelumnya:**
1. Play Console → **Release** → **Production**
2. Klik **Create new release**
3. Upload AAB versi sebelumnya (simpan backup AAB setiap release)
4. Tambahkan release notes: "Bugfix release"

> 💡 Selalu simpan file AAB setiap release di tempat yang aman!

---

## D. Kontak Darurat

| Layanan | Kontak Support |
|---|---|
| Supabase | [support.supabase.com](https://support.supabase.com) |
| Railway | [help.railway.app](https://help.railway.app) |
| Google Play | [support.google.com/googleplay/android-developer](https://support.google.com/googleplay/android-developer) |
| Google Cloud (Maps/Gemini) | [cloud.google.com/support](https://cloud.google.com/support) |

---

## E. Menonaktifkan Fitur Darurat

### Nonaktifkan AI Recommendation
Di Railway env vars, set:
```
GEMINI_API_KEY=DISABLED
```
Flutter akan menampilkan "Fitur tidak tersedia sementara".

### Nonaktifkan OSM Sync
Di Railway, nonaktifkan cron job:
1. Railway → Service → Settings → **Cron Jobs**
2. Toggle off atau hapus cron schedule sementara

### Nonaktifkan Upload Foto
Di Supabase Storage → Policies → ubah policy INSERT menjadi lebih restrictive atau hapus policy INSERT.

---

## F. Health Check Endpoints

```bash
# Backend health
curl https://[RAILWAY-URL]/api/v1/health

# Backend + Supabase connectivity
curl https://[RAILWAY-URL]/api/v1/health/ready

# OSM sync status
curl https://[RAILWAY-URL]/api/v1/sync/status \
  -H "Authorization: Bearer [USER-JWT-TOKEN]"
```

Expected responses:
- Health: `{"status":"ok","version":"1.0.0"}`
- Ready: `{"status":"ready","database":"connected"}`

---

## G. Monitoring Dasar

### Railway Metrics
- Dashboard → Service → **Metrics**
- Pantau: CPU usage, Memory, Request count, Error rate

### Supabase Monitoring
- Dashboard → **Reports**
- Pantau: API requests, DB connections, Storage usage

### Alert yang Direkomendasikan
1. Railway webhook jika deployment gagal
2. Supabase email alert jika database mendekati limit
3. Uptime monitoring via UptimeRobot (gratis): [uptimerobot.com](https://uptimerobot.com)
   - Monitor URL: `https://[RAILWAY-URL]/api/v1/health`
   - Interval: 5 menit
   - Alert via email jika down

---

*Dibuat untuk KopiFinder Phase 7 — Production Readiness*
*Tanggal: 2026-11-18*
