# DompetGueh Flutter — Android Offline

Versi Flutter dari proyek DompetGueh sebelumnya. Semua layar dirender dengan
widget Flutter (Dart): tidak ada WebView, HTML, CSS, atau server Python dalam
aplikasi ini. Logika keuangan dan PIN berjalan secara lokal di Java Android,
melalui MethodChannel, dengan penyimpanan privat aplikasi.

## Fitur

- Dashboard: anggaran bulanan, pemasukan, pengeluaran, sisa anggaran, uang keluar.
- Histori pemasukan/pengeluaran, filter jenis dan tahun, grafik 12 bulan.
- Tambah pemasukan otomatis menambah anggaran; hapus pemasukan menyesuaikannya.
- Tambah/ganti anggaran, ringkasan kategori, format Rupiah saat mengetik.
- Ubah nama, tema terang/gelap, sembunyikan anggaran, tombol aksi floating.
- PIN 4–8 angka, kunci aplikasi, lupa PIN, kode pemulihan yang dapat disalin.
- Data dan pengaturan tersimpan lokal, tidak membutuhkan akun atau internet.

Warna, font DM Sans/Manrope, susunan mobile, dan alur mengikuti desain sebelumnya.
UI dibangun ulang di Flutter sehingga hasil render tidak dijanjikan identik
100% dengan HTML/CSS pada setiap perangkat. Font asli disertakan beserta lisensi.

## Menjalankan

Dibuat dan diperiksa dengan Flutter 3.35.7 / Dart 3.9.2, JDK 17,
Android SDK Platform 35. Target aplikasi ini Android 8.0+.

1. Pasang Flutter SDK dan Android Studio/Android SDK. Pastikan `flutter doctor`
   mengenali Android SDK dan JDK 17, lalu selesaikan lisensi SDK di komputer Anda.
2. Ekstrak proyek dan buka folder ini di VS Code atau Android Studio.
3. Di terminal pada folder proyek, jalankan:

   ```bash
   flutter pub get
   flutter run
   ```

4. Untuk menghasilkan APK yang ditandatangani:

   ```bash
   flutter build apk --release
   ```

   Hasil: `build/app/outputs/flutter-apk/app-release.apk`.

Internet hanya diperlukan untuk mengunduh alat build/dependensi saat menyiapkan
proyek. APK release berjalan offline. Jangan memakai `lib/main.dart` sebagai
file tunggal: seluruh folder proyek dibutuhkan, termasuk integrasi Android.

Proyek ini dikonfigurasi untuk Android. iOS, web, dan desktop belum memiliki
implementasi penyimpanan native sehingga belum dapat dipakai sebagai target.

## Mengedit

| File | Isi |
| --- | --- |
| `lib/main.dart` | Titik awal aplikasi dan layar aktif |
| `lib/ui/theme.dart` | Warna, font, gaya tombol dan kolom isian |
| `lib/ui/home.dart` | Header, navigasi, profil, tombol floating |
| `lib/ui/dashboard.dart` | Kartu ringkasan dan kategori |
| `lib/ui/history.dart` | Histori, filter, dan tombol hapus |
| `lib/ui/chart.dart` | Grafik pemasukan/pengeluaran |
| `lib/ui/forms.dart` | Form transaksi, anggaran, dan nama |
| `lib/ui/auth.dart` | PIN dan pemulihan |
| `lib/core/models.dart` | Data, kategori, tanggal, format Rupiah |
| `lib/core/controller.dart` | State dan komunikasi penyimpanan Android |
| `android/app/src/main/java/id/terry/dompetgueh/offline/FinanceEngine.java` | Aturan keuangan, validasi, hash PIN |
| `android/app/src/main/java/id/terry/dompetgueh/offline/MainActivity.java` | MethodChannel dan penyimpanan privat |

## Data dan update dari APK sebelumnya

Application ID tetap `id.terry.dompetgueh.offline` dan kunci signing sama dengan
APK DompetGueh Offline sebelumnya. Versi ini memakai `versionCode 2` agar dapat
diinstal sebagai update. Penyimpanan transaksi, nama, dan hash PIN menggunakan
nama dan skema data yang sama. Untuk mempertahankan data, pasang sebagai update
ke APK yang sebelumnya dibuat dalam percakapan ini; jangan uninstall dahulu.
Pengaturan tema dari localStorage WebView lama tidak dimigrasikan.

Data lokal hilang jika aplikasi di-uninstall atau datanya dihapus. Data web/
Flask di komputer atau browser tidak otomatis masuk ke APK ini. Simpan kode
pemulihan saat pertama kali membuat atau mereset PIN.

Kunci signing ada di `android/signing/dompetgueh.jks`.
Alias: `dompetgueh`; password keystore/key: `dompetgueh-offline`.
Simpan proyek dan kunci ini secara pribadi. Gunakan kunci yang sama untuk update
berikutnya serta naikkan nomor versi di `pubspec.yaml`.

## Pengujian

```bash
flutter analyze
flutter test
```

Pengujian Flutter mencakup tampilan 360/390/430/800 piksel, autentikasi dan
pemulihan PIN, tambah/hapus transaksi, profil, tema, sembunyikan anggaran,
format Rupiah, penanganan gagal simpan, dan kontrak MethodChannel.

Backend Java memiliki 31 pemeriksaan tambahan untuk validasi tanggal/nominal,
perhitungan anggaran, hapus transaksi, penyimpanan, hash PIN, reset PIN, serta
kegagalan penyimpanan. Tes ini dapat dijalankan dengan JDK 17 dan Android SDK:

```bash
cd android
./gradlew :app:testReleaseUnitTest
```

Tes widget memakai data fixture. Tes Java memeriksa FinanceEngine yang sama
seperti APK. Pengujian langsung pada HP fisik belum dilakukan.
