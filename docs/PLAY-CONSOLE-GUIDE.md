# Google Play Console — Internal Testing Guide

Panduan langkah-demi-langkah untuk menyiapkan dan mengupload KopiFinder ke Google Play Console Internal Testing.

---

## Prasyarat

- [ ] Akun Google Play Console aktif ([play.google.com/console](https://play.google.com/console))
  - Biaya pendaftaran: USD 25 (sekali bayar)
- [ ] AAB release sudah berhasil dibuild: `build\app\outputs\bundle\release\app-release.aab`
- [ ] Keystore dan signing sudah dikonfigurasi (lihat KEYSTORE-SETUP-GUIDE.md)

---

## A. Membuat Aplikasi Baru di Play Console

### Langkah 1
1. Buka [Google Play Console](https://play.google.com/console)
2. Klik **Create app**

### Langkah 2 — Isi informasi aplikasi
| Field | Value |
|---|---|
| App name | KopiFinder |
| Default language | Indonesian (Bahasa Indonesia) |
| App or game | App |
| Free or paid | Free |

Centang persetujuan developer program policies, lalu klik **Create app**.

---

## B. Menyiapkan Store Listing

Isi informasi di **Store Presence → Main store listing**:

### Deskripsi singkat (max 80 karakter)
```
Temukan kafe spesialti terbaik di Jakarta dengan rekomendasi AI
```

### Deskripsi lengkap (max 4000 karakter)
```
KopiFinder adalah aplikasi penemuan kafe di lima wilayah Jakarta — Selatan, Pusat, Barat, Timur, dan Utara.

Fitur utama:
• Temukan kafe berdasarkan lokasi dan area Jakarta
• Peta interaktif dengan data OpenStreetMap
• Rekomendasi kafe berbasis AI (Google Gemini)
• Simpan kafe favorit Anda
• Tulis dan baca ulasan dari komunitas
• Bagikan pengalaman kopi di Community Feed
• Filter berdasarkan area, rating, dan fasilitas

Data kafe bersumber dari OpenStreetMap dan terus diperbarui setiap minggu.
© OpenStreetMap contributors (ODbL)
```

### Screenshot yang diperlukan (minimum 2):
- Home Screen
- Map Screen
- Cafe Detail Screen
- AI Recommendation Screen
- Community Screen

**Ukuran screenshot:** minimal 320px, maksimal 3840px.

### Ikon aplikasi
- Format: PNG, 512×512 px
- File: `assets/icons/app_icon.jpeg` (konversi ke PNG 512×512)

### Feature Graphic
- Ukuran: 1024×500 px
- Dibuat manual (Canva, Figma, dll)

---

## C. Konfigurasi App Content

### Privacy Policy
1. Play Console → **Policy** → **App content**
2. Masukkan URL Privacy Policy

**Opsi 1:** Host file `docs/PRIVACY-POLICY.md` di website (convert ke HTML).
**Opsi 2:** Upload ke GitHub Pages atau Notion.
**Opsi 3:** Gunakan layanan seperti [privacypolicygenerator.info](https://privacypolicygenerator.info)

URL contoh: `https://kopifinder.app/privacy` atau `https://github.com/[username]/kopifinder/blob/main/docs/PRIVACY-POLICY.md`

### Data Safety
Di **App content → Data safety**, isi:
| Pertanyaan | Jawaban |
|---|---|
| Apakah app mengumpulkan data user? | Ya |
| Data apa yang dikumpulkan? | Email, nama, foto, lokasi (opsional) |
| Apakah data dienkripsi? | Ya |
| Apakah user bisa minta data dihapus? | Ya |

### Ratings (Content Rating)
1. Play Console → **Policy** → **App content** → **Content ratings**
2. Isi kuesioner → pilih kategori: **Social**
3. Jawab: tidak ada kekerasan, tidak ada konten dewasa, perlu koneksi internet, ada interaksi user (UGC/ulasan)
4. Submit → rating PEGI 3 / Everyone

### Target Audience
- Target age group: **18 and over** (atau **13 and over** jika tidak ada konten dewasa)

---

## D. Upload AAB ke Internal Testing

### Langkah 1 — Buka Internal Testing track
1. Play Console → App → **Testing** → **Internal testing**
2. Klik **Create new release**

### Langkah 2 — Upload AAB
1. Klik **Upload** → pilih file `build\app\outputs\bundle\release\app-release.aab`
2. Tunggu proses upload dan verifikasi (1–5 menit)

### Langkah 3 — Konfigurasi release
| Field | Value |
|---|---|
| Release name | 1.0.0 (Internal Testing) |
| Release notes | Rilis pertama untuk internal testing |

### Langkah 4 — Manage testers
1. Klik tab **Testers** → **Create email list**
2. Nama list: `KopiFinder Internal Testers`
3. Tambahkan email tester (termasuk email Anda sendiri)
4. Simpan → Share opt-in link ke tester

### Langkah 5 — Publish
1. Klik **Save and publish**
2. Status: **Published to internal testing** (biasanya dalam 1–2 jam)

### Langkah 6 — Install via link
1. Tester membuka opt-in link di HP Android
2. Klik **Become a tester**
3. Download dari Google Play Store

---

## E. App Signing by Google Play (Rekomendasi)

Google Play mendukung **Play App Signing** untuk keamanan tambahan:
1. Play Console → **Setup** → **App signing**
2. Klik **Continue** untuk mengaktifkan Play App Signing
3. Upload upload key certificate (dari keystore Anda):
   ```bash
   keytool -export -rfc \
     -keystore android\keystores\kopifinder-release.jks \
     -alias kopifinder \
     -file upload_certificate.pem
   ```
4. Upload file `upload_certificate.pem`
5. Google akan menyimpan production signing key secara aman

---

## F. Checklist Sebelum Release ke Production

- [ ] AAB berhasil diupload dan diproses
- [ ] Semua testers internal sudah menginstall dan melaporkan tidak ada crash
- [ ] Store listing lengkap (ikon, screenshot, deskripsi, privacy policy)
- [ ] Data Safety form diisi
- [ ] Content rating selesai
- [ ] Privacy Policy online dan dapat diakses
- [ ] Backend Railway production sudah aktif
- [ ] Supabase production sudah dikonfigurasi
- [ ] Tidak ada bug blocker dari internal testing
- [ ] **Pemilik menyetujui rilis publik**

> ⚠️ Jangan publish ke Production tanpa persetujuan eksplisit pemilik.

---

*Dibuat untuk KopiFinder Phase 7 — Production Readiness*
*Tanggal: 2026-11-18*
