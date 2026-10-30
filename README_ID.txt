DOMPETGUEH — ANDROID OFFLINE

APK SIAP PASANG
Gunakan DompetGueh_Offline.apk yang disertakan terpisah.
Mendukung Android 8.0 atau lebih baru dengan Android System WebView yang diperbarui.
Tidak membutuhkan Python, server, Wi-Fi, akun, atau internet untuk dipakai.
Salin APK ke HP, buka melalui File Manager, lalu ikuti petunjuk instalasi Android.
Jika diminta, beri izin memasang aplikasi dari sumber File Manager tersebut.

TAMPILAN
HTML dan CSS tampilan asli dipakai di WebView lokal di dalam APK.
style.css dipertahankan identik dengan ZIP asli. Semua 9 bobot font DM Sans dan
Manrope disertakan sehingga tampilan tidak bergantung Google Fonts online.
Logika Flask digantikan backend Java lokal; bukan koneksi ke situs/server.
Kontrol sistem, emoji, keyboard, dan perenderan dapat berbeda antarversi Android
atau WebView. Kesamaan absolut pada setiap perangkat tidak dapat dijamin.

FITUR
- Dashboard dan Histori Keuangan, grafik, filter tahun dan jenis transaksi.
- Pemasukan otomatis menambah anggaran; menghapusnya menyesuaikan anggaran.
- Pengeluaran, ringkasan kategori, ganti/tambah anggaran, dan ubah nama pengguna.
- Format Rupiah, tema gelap, sembunyikan anggaran, tombol floating asli.
- Buat PIN, kunci, buka PIN, lupa PIN dengan kode pemulihan, salin kode.
Data disimpan di penyimpanan privat aplikasi. PIN disimpan sebagai hash bersalt
PBKDF2 SHA-256. Instalasi pertama dimulai tanpa PIN dan transaksi.
Simpan kode pemulihan saat pertama membuat PIN. Menghapus data aplikasi atau
menghapus instalasi menghilangkan data lokal. Data browser/web versi sebelumnya
tidak otomatis dipindahkan ke aplikasi ini.

EDIT DAN BUILD MELALUI ANDROID STUDIO
1. Ekstrak ZIP, buka folder DompetGueh_Android_Offline dari Android Studio.
2. Gunakan JDK 17 dan pasang Android SDK Platform 35 melalui SDK Manager.
3. Tunggu Gradle Sync selesai. Build awal membutuhkan internet untuk alat build.
4. Pilih Build > Generate Signed App Bundle / APK > APK, atau pada terminal:
   Linux / Ubuntu: chmod +x gradlew; ./gradlew assembleRelease
   Windows: gradlew.bat assembleRelease
5. Hasil: app/build/outputs/apk/release/app-release.apk

LOKASI EDIT
app/src/main/assets/index.html             Struktur UI asli
app/src/main/assets/static/style.css       Warna, layout, animasi, responsive
app/src/main/assets/static/script.js       Perilaku tampilan asli
app/src/main/assets/static/native-bridge.js Penghubung UI dan Java
app/src/main/java/id/terry/dompetgueh/offline/FinanceEngine.java
                                          Logika data dan keamanan offline
app/src/main/java/id/terry/dompetgueh/offline/MainActivity.java
                                          Konfigurasi aplikasi Android
app/src/main/res/drawable/ic_launcher.xml  Ikon launcher D sesuai identitas UI
app/build.gradle                          Identitas, versi, dan build aplikasi

SIGNING UNTUK UPDATE
Kunci untuk APK ini disertakan di signing/dompetgueh.jks.
Alias: dompetgueh
Password keystore dan key: dompetgueh-offline
Simpan proyek beserta kuncinya secara pribadi. Gunakan kunci yang sama untuk
update dan naikkan versionCode di app/build.gradle agar data tetap tersimpan.
Mengganti kunci atau applicationId membuat APK berbeda dari instalasi ini.

VALIDASI
- Kompilasi Java dan DEX berhasil; APK ditandatangani skema v2 dan v3.
- Verifikasi tanda tangan dan zipalign berhasil; tidak ada izin INTERNET.
- 31 pemeriksaan backend: PIN, pemulihan, uang, tanggal, hapus data, profil,
  penyimpanan, buka ulang, dan kegagalan simpan.
- Pengujian UI browser offline memakai FinanceEngine Java hasil kompilasi:
  pemasukan, hapus histori, profil, Rupiah, tema, sembunyikan anggaran, kunci,
  pemulihan PIN, salin kode, buka ulang, dan ukuran 360/390/430/800 piksel.
- Perbandingan screenshot browser lebar 390 piksel terhadap sumber asli:
  dashboard terang, histori terang, dashboard gelap: tidak ada perbedaan piksel.
- Belum diuji melalui emulator Android atau langsung pada HP fisik.
