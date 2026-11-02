# DompetGueh Flutter v2.1.0

Aplikasi Android offline dari sumber DompetGueh v2.1.0 yang disertakan pengguna.
Semua layar memakai widget Flutter/Dart. Logika keuangan, PIN, dan penyimpanan
privat Android berjalan lokal melalui MethodChannel; APK tidak memakai WebView,
HTML/CSS/JavaScript, server Python, akun, atau koneksi internet.

## Yang tersedia

- Layout kaca/transparan dari sumber terbaru, font DM Sans dan Manrope asli,
  warna terang/gelap, kartu anggaran, ringkasan kategori, dan grafik bulanan.
- Navigasi bawah mengambang, perpindahan halaman dengan swipe dua arah,
  animasi halaman/dialog/dropdown, tombol tekan, dan progress bar anggaran.
- Tambah pemasukan/pengeluaran, ubah anggaran, filter histori, hapus transaksi,
  format Rupiah, ubah nama, dan sembunyikan angka anggaran.
- Draft transaksi yang dibatalkan tetap tersedia saat form dibuka kembali.
- PIN 4–8 angka, kunci aplikasi, lupa PIN, dan kode pemulihan.
- Logo DG dari lampiran digunakan untuk ikon Android dan logo dalam aplikasi.
- Versi Android `2.1.0`, versionCode `3` (`pubspec.yaml: 2.1.0+3`).

UI dan gerakan dibangun ulang mengikuti HTML/CSS/JavaScript dari ZIP terbaru.
Ukuran serta posisi komponen utama dashboard telah dibandingkan dengan sumber
pada lebar 390 piksel. Karena Flutter dan browser memakai mesin render berbeda,
kesamaan piksel 100% pada setiap ukuran layar/perangkat belum dapat dijamin.
Font asli beserta lisensinya disertakan. Bentuk bingkai ikon launcher mengikuti
masker launcher Android masing-masing perangkat.

## Memasang APK dan memperbarui versi sebelumnya

Untuk memperbarui aplikasi yang terpasang, build APK dengan kunci signing yang
sama dan versionCode yang lebih tinggi. Jangan uninstall atau hapus data.
Konfigurasi yang dipertahankan dari source v2.1.0:

| Komponen | Nilai |
| --- | --- |
| Application ID | `id.terry.dompetgueh.offline` |
| Versi baru | `2.1.0`, versionCode `3` (sebelumnya `2`) |
| Sertifikat signing | Ditentukan oleh kunci saat membangun APK |
| Data keuangan/PIN | SharedPreferences `dompetgueh_data`, key `database` |
| Tema/sembunyikan angka | SharedPreferences `dompetgueh_flutter_ui` |
| Android minimum | Android 8.0 / API 26 |

Update Android memerlukan ID paket dan sertifikat yang sama, serta versionCode
lebih tinggi. APK lama dari pembuat/kunci signing lain tidak otomatis kompatibel.
Data browser/Flask di komputer tidak otomatis masuk ke aplikasi Android.
Tema dari localStorage pada APK WebView lama tidak dimigrasikan. Data lokal
hilang jika aplikasi di-uninstall atau datanya dihapus. Simpan kode pemulihan
saat pertama kali membuat atau mereset PIN.

## Menjalankan dan membangun source

Dibuat dengan Flutter 3.35.7, Dart 3.9.2, JDK 17, Android SDK Platform/Build Tools
35, NDK 27.0.12077973. Target aplikasi ini Android; implementasi penyimpanan
native iOS/web/desktop belum tersedia.

1. Pasang Flutter SDK dan Android Studio/Android SDK dengan JDK 17.
2. Jalankan `flutter doctor` dan selesaikan lisensi SDK di komputer Anda.
3. Buka seluruh folder proyek di Android Studio atau VS Code, lalu jalankan:

   ```bash
   flutter pub get
   flutter run
   ```

4. Konfigurasikan kunci signing sesuai bagian di bawah, lalu buat APK release:

   ```bash
   flutter build apk --release
   ```

   Hasil: `build/app/outputs/flutter-apk/app-release.apk`.

Internet diperlukan saat mengunduh alat build/dependensi. Setelah terpasang,
APK release bekerja offline. Seluruh folder proyek dibutuhkan, termasuk folder
Android; `lib/main.dart` saja tidak cukup.

## Lokasi pengeditan

| File | Isi |
| --- | --- |
| `pubspec.yaml` | Nomor versi, aset, font, dependensi |
| `lib/main.dart` | Titik awal, locale Indonesia, layar aktif |
| `lib/ui/theme.dart` | Warna, font, gaya form dan tombol |
| `lib/ui/visuals.dart` | Latar, kaca, ikon, animasi dialog/progress bar |
| `lib/ui/home.dart` | Header, dock navigasi, swipe, profil |
| `lib/ui/dashboard.dart` | Kartu anggaran dan kategori |
| `lib/ui/history.dart` | Histori, filter, konfirmasi hapus |
| `lib/ui/chart.dart` | Grafik pemasukan/pengeluaran |
| `lib/ui/forms.dart` | Transaksi, anggaran, nama, draft form |
| `lib/ui/glass_select.dart` | Dropdown kaca dan interaksi keyboard |
| `lib/ui/auth.dart` | PIN, kunci aplikasi, pemulihan |
| `lib/core/models.dart` | Model data, kategori, format Rupiah/tanggal |
| `lib/core/controller.dart` | State, permintaan dan penyimpanan preferensi |
| `assets/images/logo.jpeg` | Logo dalam aplikasi |
| `android/app/src/main/res/mipmap-*` | Ikon launcher Android |
| `android/app/src/main/res/drawable-nodpi/dg_logo.jpg` | Logo ikon adaptif |
| `android/app/src/main/java/id/terry/dompetgueh/offline/FinanceEngine.java` | Aturan keuangan, validasi, hash PIN |
| `android/app/src/main/java/id/terry/dompetgueh/offline/MainActivity.java` | MethodChannel dan penyimpanan privat |

## Signing APK release

Kunci signing tidak disertakan dalam proyek yang siap diunggah ke GitHub.
Simpan `dompetgueh.jks` dari arsip asli di lokasi pribadi. Jangan unggah kunci,
password, atau `android/key.properties` ke repository. Bila kunci atau password
sudah pernah masuk ke repository publik, anggap kunci tersebut terpapar.

1. Salin `android/key.properties.example` menjadi `android/key.properties`.
2. Isi `storeFile` dengan path absolut ke file keystore, lalu isi alias dan
   password sesuai kunci Anda. File ini sudah tercantum di `.gitignore`.
3. Jalankan `flutter build apk --release`. Tanpa `key.properties`, konfigurasi
   release tidak ditandatangani dan APK tersebut tidak dapat dipasang sebagai
   pembaruan.

Untuk memperbarui instalasi lama tanpa menghapus data, gunakan application ID
`id.terry.dompetgueh.offline` dan kunci signing yang sama dengan APK lama.
`versionCode` juga harus lebih tinggi daripada versi yang sudah terpasang;
`2.1.0+3` hanya dapat memperbarui versi dengan versionCode kurang dari 3.
Jangan uninstall atau hapus data. Perubahan kunci memerlukan mekanisme rotasi
kunci yang didukung Android atau distribusi sebagai aplikasi baru.

## Pengujian

```bash
flutter analyze
flutter test
cd android
./gradlew :app:testReleaseUnitTest
```

Tes widget menggunakan fixture; tes Java menguji FinanceEngine yang sama dengan
aplikasi. Jalankan pengujian tersebut setelah menyelesaikan konflik merge dan
sebelum membuat pull request. Hasil pemeriksaan historis di `VALIDASI.txt`
dan `APK_SHA256.txt` berlaku untuk APK lama, bukan untuk source hasil merge ini.
