# Railway Deployment Guide — KopiFinder Backend

Panduan langkah-demi-langkah untuk deploy backend KopiFinder ke Railway staging.

---

## Prasyarat

Sebelum mulai, pastikan Anda memiliki:
- [ ] Akun Railway ([https://railway.app](https://railway.app))
- [ ] Repository GitHub berisi `kopifinder-backend/`
- [ ] Supabase project sudah aktif dan migration sudah dijalankan
- [ ] Semua environment variable (lihat bagian C)

---

## A. Membuat Railway Project

### Langkah 1 — Login ke Railway
1. Buka [https://railway.app](https://railway.app)
2. Klik **Login** → gunakan GitHub account

### Langkah 2 — Buat Project Baru
1. Klik **New Project**
2. Pilih **Deploy from GitHub repo**
3. Authorize Railway ke akun GitHub Anda
4. Pilih repository `kopifinder` (atau nama repo yang sesuai)
5. Railway akan mendeteksi konfigurasi dari `railway.toml`

### Langkah 3 — Konfigurasi Root Directory
Karena backend berada di subfolder, atur **Root Directory**:
1. Di Railway project → klik service yang baru dibuat
2. Klik tab **Settings**
3. Di **Root Directory** → isi: `kopifinder-backend`
4. Railway akan build hanya dari folder tersebut

---

## B. Set Environment Variables

Di Railway project → klik service → tab **Variables** → klik **New Variable**.

Tambahkan variabel berikut satu per satu:

### Supabase
| Key | Value | Keterangan |
|---|---|---|
| `SUPABASE_URL` | `https://[PROJECT-REF].supabase.co` | Dari Supabase Dashboard → Project Settings → API |
| `SUPABASE_ANON_KEY` | `eyJ...` | Supabase anon/public key |
| `SUPABASE_SERVICE_ROLE_KEY` | `eyJ...` | Supabase service role key (rahasia!) |

**Cara ambil dari Supabase:**
1. Supabase Dashboard → **Project Settings** → **API**
2. Copy `URL`, `anon public`, dan `service_role` key

### Google Gemini AI
| Key | Value | Keterangan |
|---|---|---|
| `GEMINI_API_KEY` | `AIza...` | Dari Google AI Studio |
| `GEMINI_MODEL` | `gemini-1.5-flash` | Model yang digunakan |

**Cara ambil:** [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)

### App Config
| Key | Value | Keterangan |
|---|---|---|
| `PORT` | `3000` | Port backend |
| `NODE_ENV` | `production` | Environment mode |
| `CORS_ORIGINS` | `*` | Atau URL spesifik Flutter app |
| `ADMIN_USER_IDS` | `uuid1,uuid2` | User ID admin dari tabel users |
| `ADMIN_SYNC_TOKEN` | `random-secret-token` | Token untuk trigger sync manual |

**Generate ADMIN_SYNC_TOKEN:**
```bash
# Di terminal lokal
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Google Maps (Opsional untuk Backend)
| Key | Value |
|---|---|
| `GOOGLE_MAPS_API_KEY` | API key dari Google Cloud Console |

---

## C. Trigger Deployment Pertama

1. Setelah semua variabel diisi, Railway otomatis trigger deploy
2. Pantau progress di tab **Deployments**
3. Build menggunakan Nixpacks (sesuai `railway.toml`)
4. Proses build biasanya 2–5 menit

**Jika build gagal:**
- Klik deployment yang gagal → lihat **Build Logs**
- Error umum: missing env var, TypeScript error (jalankan `npx tsc --noEmit` lokal dulu)

---

## D. Verifikasi Deployment

### Health Check
Setelah deploy berhasil, Railway memberikan URL publik (format: `https://kopifinder-backend-xxx.railway.app`).

```bash
# Cek health endpoint
curl https://[RAILWAY-URL]/api/v1/health

# Expected response:
{
  "status": "ok",
  "timestamp": "2026-11-18T...",
  "version": "1.0.0",
  "environment": "production"
}

# Cek readiness (koneksi ke Supabase)
curl https://[RAILWAY-URL]/api/v1/health/ready

# Expected response:
{
  "status": "ready",
  "database": "connected"
}
```

### Test Auth Endpoint
```bash
curl -X POST https://[RAILWAY-URL]/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!","username":"testuser"}'
```

---

## E. Update Flutter App — Backend URL

Setelah Railway URL diketahui, update konfigurasi Flutter:

**File:** `d:\IT\kopifinder\lib\core\config\app_config.dart`

Ganti URL backend dari:
```dart
// Emulator
static const String baseUrl = 'http://10.0.2.2:3000';
```
Menjadi:
```dart
// Railway Staging
static const String baseUrl = 'https://[RAILWAY-URL]';
```

Atau gunakan `--dart-define` saat build:
```bash
flutter build apk --debug \
  --dart-define=BACKEND_URL=https://[RAILWAY-URL]
```

---

## F. OSM Sync di Railway

Railway menjalankan OSM sync otomatis setiap Minggu pukul 02:00 WIB (19:00 UTC Sabtu) sesuai konfigurasi di `railway.toml`.

**Trigger sync manual:**
```bash
# Via Railway CLI
railway run npm run sync:osm:all

# Via API endpoint (dengan ADMIN_SYNC_TOKEN)
curl -X POST https://[RAILWAY-URL]/api/v1/admin/sync/osm \
  -H "Authorization: Bearer [ADMIN_SYNC_TOKEN]"
```

---

## G. Monitoring & Logs di Railway

### Melihat Logs Real-time
1. Railway Dashboard → project → service
2. Tab **Logs** → pilih deployment aktif
3. Filter: `level:error` untuk error saja

### Setup Alert (Opsional)
Railway mendukung notifikasi via:
- Email (built-in)
- Webhook (ke Slack, Discord, dll)

**Setup webhook:**
1. Railway Dashboard → **Settings** → **Notifications**
2. Tambah webhook URL (Slack/Discord/custom)
3. Pilih event: `Deployment Failed`, `Deployment Crashed`

---

## H. Rollback Deployment

Jika deployment terbaru bermasalah:
1. Railway Dashboard → **Deployments**
2. Klik deployment sebelumnya yang stabil
3. Klik **Rollback** → konfirmasi

Railway akan mengembalikan ke versi sebelumnya dalam 1–2 menit.

---

## I. Checklist Deployment Staging

- [ ] Railway project dibuat
- [ ] Root Directory = `kopifinder-backend`
- [ ] Semua env vars diisi (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, GEMINI_API_KEY, PORT, NODE_ENV, CORS_ORIGINS, ADMIN_SYNC_TOKEN)
- [ ] Build berhasil (exit code 0)
- [ ] `GET /api/v1/health` → `{"status":"ok"}`
- [ ] `GET /api/v1/health/ready` → `{"status":"ready","database":"connected"}`
- [ ] Auth endpoint dapat diakses
- [ ] OSM sync dapat dijalankan manual
- [ ] Flutter app diupdate dengan Railway URL baru
- [ ] APK debug diinstall di HP Android → test end-to-end

---

*Dibuat untuk KopiFinder Phase 6 — Deployment Staging*
*Tanggal: 2026-11-18*
