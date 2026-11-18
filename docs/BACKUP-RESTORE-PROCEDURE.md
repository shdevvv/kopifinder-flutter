# Backup & Restore Procedure — KopiFinder

Panduan backup dan restore database KopiFinder di Supabase + Railway.

---

## A. Backup Database Supabase

### Metode 1 — Supabase Automatic Backups (Rekomendasi)

Supabase melakukan backup otomatis sesuai paket:

| Paket Supabase | Frekuensi Backup | Retensi |
|---|---|---|
| Free | Daily (sekali sehari) | 7 hari |
| Pro | Daily | 30 hari |
| Team | Daily + PITR | 90 hari |
| Enterprise | PITR (Point-in-Time Recovery) | Custom |

**Cara restore dari backup otomatis:**
1. Buka Supabase Dashboard → **Project Settings** → **Database**
2. Scroll ke bagian **Backups**
3. Pilih tanggal backup yang diinginkan
4. Klik **Restore**
5. Konfirmasi restore — proses memakan waktu 5–15 menit

> ⚠️ Restore akan menggantikan seluruh data saat ini dengan data dari backup tersebut.

---

### Metode 2 — Manual Backup dengan pg_dump

Lakukan backup manual menggunakan `pg_dump` dari terminal lokal.

**Prasyarat:**
- PostgreSQL client terinstall (`pg_dump` command available)
- Supabase connection string tersedia

**Ambil connection string:**
1. Supabase Dashboard → **Project Settings** → **Database**
2. Copy **Connection String** (URI format)
   ```
   postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
   ```

**Jalankan pg_dump:**
```bash
# Backup seluruh database
pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  --format=custom \
  --no-acl \
  --no-owner \
  --file="kopifinder_backup_$(date +%Y%m%d_%H%M%S).dump"

# Backup hanya schema (tanpa data)
pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  --schema-only \
  --no-acl \
  --no-owner \
  --file="kopifinder_schema_$(date +%Y%m%d_%H%M%S).sql"

# Backup hanya data (tanpa schema)
pg_dump "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  --data-only \
  --no-acl \
  --no-owner \
  --file="kopifinder_data_$(date +%Y%m%d_%H%M%S).dump"
```

**Simpan file backup di:**
- Local: `d:\IT\kopifinder\backups\`
- Cloud: Google Drive / Dropbox / S3 bucket

---

### Metode 3 — Export Data via Supabase SQL Editor

Untuk backup tabel spesifik:
```sql
-- Contoh: backup tabel cafes ke CSV
COPY cafes TO STDOUT WITH CSV HEADER;
```
Jalankan di SQL Editor → klik **Download CSV**.

---

## B. Restore Database

### Restore dari pg_dump File

```bash
# Restore dari custom format dump
pg_restore \
  --dbname="postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  --no-acl \
  --no-owner \
  --verbose \
  kopifinder_backup_20261118_120000.dump

# Restore dari SQL file
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -f kopifinder_schema_20261118_120000.sql
```

---

## C. Railway — Log Retention & Monitoring

### Log Railway

Railway menyimpan log deployment dan runtime.

**Melihat log di Railway:**
1. Buka Railway Dashboard → project KopiFinder → **Deployments**
2. Klik deployment yang aktif → tab **Logs**
3. Filter berdasarkan level: `info`, `error`, `warn`

**Retensi log Railway:**
- Plan Free: 7 hari
- Plan Pro: 30 hari

**Export log Railway** (via Railway CLI):
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Stream log terkini
railway logs

# Export log ke file
railway logs > kopifinder_railway_logs_$(date +%Y%m%d).txt
```

---

## D. Jadwal Backup yang Direkomendasikan

| Jenis | Frekuensi | Metode | Simpan Di |
|---|---|---|---|
| Database full | Mingguan (Minggu malam) | pg_dump | Google Drive |
| Database schema | Setiap ada perubahan migration | pg_dump --schema-only | Git repo (docs/backups/) |
| Railway logs | Bulanan atau saat ada insiden | railway logs export | Local folder |
| Supabase auto backup | Otomatis setiap hari | Supabase Dashboard | — |

---

## E. Disaster Recovery Checklist

Jika terjadi masalah serius (data hilang, database corrupt):

1. **Jangan panik** — Supabase menyimpan backup otomatis harian
2. Tentukan titik waktu restore yang diinginkan
3. Backup data terkini sebelum restore (jika masih bisa diakses)
4. Hubungi Supabase Support jika perlu PITR di luar dashboard
5. Setelah restore selesai, verifikasi integritas data:
   ```sql
   -- Cek jumlah record di tabel utama
   SELECT
     (SELECT COUNT(*) FROM cafes) AS total_cafes,
     (SELECT COUNT(*) FROM users) AS total_users,
     (SELECT COUNT(*) FROM reviews) AS total_reviews,
     (SELECT COUNT(*) FROM osm_places) AS total_osm_places;
   ```
6. Re-run OSM sync jika data OSM hilang:
   ```bash
   # Di Railway terminal atau lokal
   npm run sync:osm:all
   ```
7. Notify team bahwa restore selesai

---

*Dibuat untuk KopiFinder Phase 6 — Deployment Staging*
*Tanggal: 2026-11-18*
