# Panduan menyelesaikan merge DompetGueh

Konflik dalam arsip diselesaikan dengan memilih sisi `HEAD` (versi 2.1.0+3)
secara konsisten. Sisi `origin/main` yang tertulis dalam penanda konflik tidak
digabungkan secara terpisah. ZIP ini tidak menyertakan riwayat atau commit dasar,
sehingga periksa kembali perubahan kedua branch di GitHub sebelum merge.

1. Ekstrak ZIP ini ke folder terpisah, lalu salin isinya ke folder repository lokal
   yang sedang menyelesaikan konflik. Tinjau perbedaannya sebelum menimpa file.
2. Jalankan `git status` untuk melihat file konflik yang tersisa. Tandai file
   yang telah diperiksa dengan `git add <nama-file>` dan tinjau `git diff --cached`.
   Jika ada konflik lain yang tidak termasuk dalam ZIP, selesaikan secara manual.
3. Jalankan `flutter pub get`, `flutter analyze`, `flutter test`, dan
   `cd android && ./gradlew :app:testReleaseUnitTest`, lalu kembali ke root.
   Pemeriksaan Flutter/Android ini belum dijalankan pada hasil resolusi ZIP.
4. Setelah pemeriksaan lulus, buat commit dan push branch, kemudian buka atau
   perbarui pull request. GitHub akan memeriksa konflik dan aturan repository.

## Kunci signing

Keystore tidak disertakan. Simpan file kunci dari ZIP asli di luar repository,
isi `android/key.properties` menggunakan contoh, dan jangan commit file tersebut.
Bila file kunci sudah terlacak Git, `.gitignore` tidak menghapusnya dari indeks;
hapus dari indeks dengan `git rm --cached <path-ke-kunci>` setelah menyimpan
salinan aman. Periksa juga riwayat Git jika pernah terunggah.
Versi 2.1.0+3 hanya dapat memperbarui APK yang versionCode-nya kurang dari 3 dan
ditandatangani dengan kunci yang sama. Panduan build lengkap ada di README.md.
