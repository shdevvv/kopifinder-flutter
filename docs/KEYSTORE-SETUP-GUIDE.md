# Keystore Setup Guide — KopiFinder Android Release

Panduan membuat dan mengkonfigurasi Android signing keystore untuk release build KopiFinder.

> ⚠️ **PENTING:** File keystore adalah kredensial produksi yang tidak dapat diganti jika hilang.
> Simpan di tempat aman (Google Drive, password manager) dan JANGAN commit ke Git.

---

## A. Membuat Keystore Baru

### Prasyarat
- Java JDK terinstall (`keytool` command available)
- Atau Android Studio sudah terinstall

### Langkah 1 — Buat folder keystores
```bash
# Di root project kopifinder
mkdir android\keystores
```

### Langkah 2 — Generate keystore dengan keytool
```bash
keytool -genkey -v \
  -keystore android\keystores\kopifinder-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias kopifinder
```

**Isi pertanyaan yang muncul:**
- `Enter keystore password:` → buat password kuat (minimal 8 karakter)
- `Re-enter new password:` → ulangi password
- `What is your first and last name?` → nama developer (contoh: Stephanie Halim)
- `What is the name of your organizational unit?` → (opsional, tekan Enter)
- `What is the name of your organization?` → KopiFinder
- `What is the name of your City or Locality?` → Jakarta
- `What is the name of your State or Province?` → DKI Jakarta
- `What is the two-letter country code?` → ID
- Konfirmasi: ketik `yes`
- `Enter key password for <kopifinder>:` → tekan Enter (sama dengan keystore password)

### Langkah 3 — Buat key.properties
Buat file `android\key.properties` (BUKAN `key.properties.example`):

```properties
storePassword=KEYSTORE_PASSWORD_ANDA
keyPassword=KEY_PASSWORD_ANDA
keyAlias=kopifinder
storeFile=../keystores/kopifinder-release.jks
```

Ganti `KEYSTORE_PASSWORD_ANDA` dan `KEY_PASSWORD_ANDA` dengan password yang dibuat di Langkah 2.

---

## B. Verifikasi Keystore

```bash
keytool -list -v \
  -keystore android\keystores\kopifinder-release.jks \
  -alias kopifinder
```

Output harus menampilkan:
- Alias name: `kopifinder`
- Entry type: `PrivateKeyEntry`
- Certificate fingerprints (SHA-256) — catat ini untuk Play Console

---

## C. Build Release AAB

Setelah keystore dan `key.properties` siap:

```bash
# Dari root project kopifinder
flutter build appbundle --release
```

File AAB akan berada di:
```
build\app\outputs\bundle\release\app-release.aab
```

---

## D. Backup Keystore

**WAJIB** backup file ini di tempat aman:
- `android\keystores\kopifinder-release.jks`
- `android\key.properties`

Simpan di:
- Google Drive (folder private/locked)
- Password manager (Bitwarden, 1Password, dll)
- USB/hard drive terpisah

> ⚠️ Jika keystore hilang, aplikasi **tidak dapat diupdate** di Google Play.
> Satu-satunya opsi adalah membuat aplikasi baru dengan ID yang berbeda.

---

## E. Upload ke Google Play Console

Setelah AAB berhasil dibuild:

1. Buka [Google Play Console](https://play.google.com/console)
2. Pilih aplikasi KopiFinder → **Testing** → **Internal testing**
3. Klik **Create new release**
4. Upload file `app-release.aab`
5. Isi release notes
6. Klik **Save and publish**

### Catatan App Signing by Google Play
Google Play mendukup **Play App Signing** — Google menyimpan signing key production.
Keystore yang Anda buat digunakan sebagai "upload key" saja.

**Aktifkan Play App Signing:**
1. Play Console → App → **Setup** → **App signing**
2. Ikuti wizard untuk mengupload upload key certificate
3. Setelah aktif, Google akan re-sign APK dengan production key

---

## F. Daftar File yang Harus Dijaga

| File | Di Git? | Di Backup? | Keterangan |
|---|---|---|---|
| `android/keystores/kopifinder-release.jks` | ❌ TIDAK | ✅ WAJIB | Signing keystore |
| `android/key.properties` | ❌ TIDAK | ✅ WAJIB | Signing passwords |
| `android/key.properties.example` | ✅ YA | — | Template (tanpa nilai nyata) |
| `kopifinder-backend/.env` | ❌ TIDAK | ✅ WAJIB | Backend secrets |

---

*Dibuat untuk KopiFinder Phase 7 — Production Readiness*
*Tanggal: 2026-11-18*
