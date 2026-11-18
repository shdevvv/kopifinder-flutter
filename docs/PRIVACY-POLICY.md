# Kebijakan Privasi — KopiFinder

**Terakhir diperbarui:** 18 November 2026

KopiFinder ("kami", "aplikasi") berkomitmen untuk melindungi privasi pengguna. Kebijakan ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi Anda.

---

## 1. Informasi yang Kami Kumpulkan

### 1.1 Informasi yang Anda Berikan
- **Akun:** nama lengkap, username, alamat email, dan kata sandi saat registrasi.
- **Konten:** ulasan kafe, posting komunitas, komentar, dan foto yang Anda unggah.
- **Preferensi:** kafe yang Anda simpan (bookmark).

### 1.2 Informasi yang Dikumpulkan Otomatis
- **Lokasi:** koordinat GPS perangkat Anda, hanya saat Anda mengizinkan dan menggunakan fitur peta. Kami tidak melacak lokasi di latar belakang.
- **Log aplikasi:** informasi teknis seperti jenis perangkat, versi OS, dan error report untuk perbaikan aplikasi.

### 1.3 Data Kafe (OpenStreetMap)
Data kafe di KopiFinder bersumber dari OpenStreetMap (OSM) di bawah lisensi Open Database License (ODbL). Kami tidak mengklaim kepemilikan data tersebut.

---

## 2. Bagaimana Kami Menggunakan Informasi

| Tujuan | Data yang Digunakan |
|---|---|
| Autentikasi dan keamanan akun | Email, password (hashed) |
| Menampilkan profil publik | Nama, username, foto profil |
| Fitur komunitas | Posting, ulasan, komentar |
| Rekomendasi kafe berbasis AI | Preferensi pencarian, riwayat interaksi |
| Peta dan pencarian terdekat | Koordinat lokasi (saat diizinkan) |
| Perbaikan aplikasi | Log teknis anonim |

Kami **tidak** menjual, menyewakan, atau memperdagangkan data pribadi Anda kepada pihak ketiga.

---

## 3. Penyimpanan dan Keamanan Data

- Data akun dan konten disimpan di **Supabase** (infrastruktur PostgreSQL terenkripsi).
- Foto disimpan di **Supabase Storage** dengan akses terbatas berdasarkan kepemilikan.
- Komunikasi antara aplikasi dan server menggunakan **HTTPS/TLS**.
- Kata sandi tidak pernah disimpan dalam bentuk teks biasa — kami menggunakan hash yang dikelola Supabase Auth.
- Kami menerapkan Row Level Security (RLS) di database untuk memastikan data pengguna hanya dapat diakses oleh pemiliknya.

---

## 4. Berbagi Data dengan Pihak Ketiga

Kami menggunakan layanan pihak ketiga berikut:

| Layanan | Tujuan | Kebijakan Privasi |
|---|---|---|
| Supabase | Database dan autentikasi | [supabase.com/privacy](https://supabase.com/privacy) |
| Google Maps | Tampilan peta | [policies.google.com](https://policies.google.com/privacy) |
| Google Gemini AI | Rekomendasi kafe berbasis AI | [ai.google.dev/privacy](https://ai.google.dev/privacy) |
| OpenStreetMap / Overpass API | Data lokasi kafe | [wiki.osm.org/Privacy_Policy](https://wiki.openstreetmap.org/wiki/Privacy_Policy) |
| Railway | Hosting backend | [railway.app/legal/privacy](https://railway.app/legal/privacy) |

---

## 5. Izin Aplikasi

| Izin | Alasan |
|---|---|
| `ACCESS_FINE_LOCATION` | Menampilkan kafe terdekat di peta |
| `ACCESS_COARSE_LOCATION` | Alternatif lokasi perkiraan |
| `CAMERA` | Mengambil foto untuk ulasan atau profil |
| `READ_EXTERNAL_STORAGE` | Memilih foto dari galeri |
| `INTERNET` | Mengakses data kafe dan backend |

Izin lokasi hanya aktif saat Anda membuka fitur peta dan **tidak** berjalan di latar belakang.

---

## 6. Hak Pengguna

Anda berhak untuk:
- **Mengakses** data pribadi Anda melalui halaman Profil.
- **Mengedit** informasi akun Anda kapan saja.
- **Menghapus** posting, ulasan, atau komentar Anda.
- **Menghapus akun** beserta seluruh data Anda secara permanen.

Untuk menghapus akun, buka **Profil → Pengaturan → Hapus Akun** atau hubungi kami di email di bawah.

---

## 7. Retensi Data

- Data akun aktif disimpan selama akun ada.
- Setelah penghapusan akun, data pribadi dihapus dalam 30 hari.
- Log teknis anonim disimpan maksimal 90 hari.
- Data kafe dari OSM mengikuti siklus sinkronisasi mingguan.

---

## 8. Anak-anak

KopiFinder tidak ditujukan untuk anak-anak di bawah 13 tahun. Kami tidak secara sengaja mengumpulkan data dari anak-anak.

---

## 9. Perubahan Kebijakan

Kami dapat memperbarui kebijakan ini. Perubahan signifikan akan diinformasikan melalui notifikasi di aplikasi. Penggunaan berkelanjutan setelah perubahan dianggap sebagai persetujuan.

---

## 10. Kontak

Jika ada pertanyaan tentang kebijakan privasi ini, hubungi kami di:
- **Email:** privacy@kopifinder.app
- **Website:** https://kopifinder.app/privacy

---

## Atribusi Data OpenStreetMap

Data kafe di KopiFinder menggunakan data dari **OpenStreetMap** yang tersedia di bawah lisensi **Open Database License (ODbL)**.
© OpenStreetMap contributors

---

*KopiFinder — Jakarta Specialty Cafe Discovery*
