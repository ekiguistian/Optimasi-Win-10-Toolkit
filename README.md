# Optimasi Windows 10 Toolkit

Toolkit berbasis **Windows PowerShell 5.1** untuk membantu pengguna laptop/PC dengan sumber daya terbatas menganalisis penggunaan RAM dan mengelola sebagian beban latar belakang Windows 10.

> **Status: versi awal / experimental.** Belum dinyatakan siap produksi. Uji pada perangkat cadangan atau setelah membuat System Restore Point. Baca script dan pahami setiap perubahan sebelum menjalankan fitur yang mengubah konfigurasi Windows.

## Tujuan proyek

- Mengidentifikasi proses, service, aplikasi UWP, dan program startup yang menggunakan sumber daya.
- Mengurangi beban latar belakang secara selektif, bukan melakukan debloat agresif.
- Menyediakan pencatatan baseline untuk sebagian pengaturan agar perubahan tertentu dapat dipulihkan.
- Memprioritaskan stabilitas, keamanan, dan responsivitas sistem dibanding mengejar angka RAM idle tertentu.

Toolkit ini **tidak dapat menambah kapasitas RAM fisik** dan tidak menjamin angka penggunaan RAM tertentu. Hasil bergantung pada edisi Windows, driver, aplikasi, layanan vendor, dan kondisi perangkat.

## Fitur dan fungsi menu

Script utama: `scripts/Optimasi-Windows-10-Toolkit.ps1`

| Menu | Fitur | Fungsi |
|---:|---|---|
| 1 | Ringkasan penggunaan RAM | Menampilkan informasi memori fisik dan penggunaan RAM saat ini. |
| 2 | Service yang sedang Running | Menampilkan daftar service Windows yang sedang berjalan untuk audit. |
| 3 | Service opsional | Menampilkan kandidat service yang dapat dievaluasi berdasarkan kebutuhan perangkat. |
| 4 | Disable service terpilih | Menonaktifkan service opsional yang dipilih secara manual. Gunakan hanya jika memahami dampaknya. |
| 5 | Set service ke Manual | Mengubah startup type service terpilih menjadi Manual, sebagai alternatif yang lebih konservatif daripada Disabled. |
| 6 | Aplikasi UWP / background | Menampilkan aplikasi UWP dan informasi pengaturan aktivitas background yang dapat dibaca. |
| 7 | Batasi background UWP | Mengubah izin background untuk aplikasi yang didukung pada akun pengguna saat ini. Tidak mengendalikan semua aplikasi desktop. |
| 8 | Aplikasi Startup | Menampilkan program startup yang terdeteksi melalui WMI/CIM. |
| 9 | 20 proses pemakai RAM terbesar | Mengurutkan proses berdasarkan Working Set untuk membantu menemukan aplikasi yang boros memori. |
| 10 | Optimasi aman | Menerapkan sejumlah pengaturan terbatas terkait aplikasi background, Game DVR, visual effects, dan pagefile. Tinjau perubahan sebelum dan sesudah menjalankan menu ini. |
| 11 | System Managed Pagefile | Mengaktifkan pengelolaan pagefile otomatis oleh Windows. Disarankan untuk perangkat dengan RAM terbatas; jangan menonaktifkan pagefile. |
| 12 | Restore baseline | Memulihkan pengaturan registry, service yang dicatat, dan konfigurasi pagefile dari baseline yang dibuat toolkit. Bukan full system restore. |
| 13 | Export laporan sistem | Mengekspor ringkasan informasi sistem untuk kebutuhan troubleshooting. |
| 14 | Folder backup dan log | Membuka direktori penyimpanan baseline dan log toolkit. |
| 15 | Katalog aplikasi bawaan | Menampilkan kandidat aplikasi UWP konsumen yang dapat dievaluasi sebelum uninstall. |
| 16 | Uninstall aplikasi UWP | Menghapus aplikasi yang dipilih untuk akun pengguna saat ini. Backup baseline tidak menyimpan installer dan tidak dapat memasang ulang aplikasi. |
| 17 | Uninstall Microsoft Edge (advanced) | Memanggil uninstaller bawaan Edge jika tersedia. Eksperimental, tidak direkomendasikan sebagai optimasi RAM, dan tidak dijamin berhasil. |
| 0 | Keluar | Menutup toolkit. |

## Persyaratan

- Windows 10, target pengembangan saat ini Windows 10 Pro 22H2 x64.
- Windows PowerShell **5.1** (`powershell.exe`), bukan persyaratan PowerShell 7.
- Menjalankan script dengan hak **Administrator**.
- Koneksi internet hanya diperlukan untuk mengunduh repository; toolkit tidak membutuhkan koneksi internet untuk menjalankan fungsi lokal.
- Disarankan membuat System Restore Point dan memiliki backup data penting sebelum mengubah konfigurasi.

Kompatibilitas Windows 11 dan edisi Windows lain belum menjadi target pengujian. Proyek ini belum melewati matriks pengujian lintas vendor laptop.

## Cara penggunaan

### Opsi 1 — Clone menggunakan Git

Buka Command Prompt atau PowerShell:

```powershell
git clone https://github.com/ekiguistian/Optimasi-Win-10-Toolkit.git
cd Optimasi-Win-10-Toolkit
```

### Opsi 2 — Unduh ZIP

1. Buka halaman repository: <https://github.com/ekiguistian/Optimasi-Win-10-Toolkit>.
2. Pilih **Code → Download ZIP**.
3. Ekstrak ZIP ke folder yang mudah diakses, misalnya `C:\Tools\Optimasi-Win-10-Toolkit`.

### Jalankan toolkit

1. Buka **Windows PowerShell 5.1** dengan memilih **Run as administrator**.
2. Masuk ke direktori hasil clone/ekstrak. Sesuaikan path jika lokasi berbeda:

```powershell
cd C:\Tools\Optimasi-Win-10-Toolkit
```

3. Jika file ditandai berasal dari internet dan kebijakan `RemoteSigned` memblokirnya, periksa dahulu sumber dan isi script. Setelah yakin file tepercaya, buka blokir file tersebut secara spesifik:

```powershell
Unblock-File .\scripts\Optimasi-Windows-10-Toolkit.ps1
```

4. Jalankan script. Jika kebijakan eksekusi lokal memblokirnya, gunakan bypass **hanya untuk sesi PowerShell yang sedang dibuka**:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\scripts\Optimasi-Windows-10-Toolkit.ps1
```

Pengaturan `Process` tidak mengubah kebijakan permanen untuk seluruh komputer. Jangan mengubah Execution Policy ke `Unrestricted` atau menonaktifkan kebijakan keamanan secara permanen hanya untuk menjalankan toolkit. Kebijakan Group Policy organisasi dapat tetap membatasi eksekusi script.

## Alur penggunaan yang disarankan

1. Buat System Restore Point dan backup data penting.
2. Jalankan menu **1, 2, 8, dan 9** untuk mengambil kondisi awal RAM, service, startup, dan proses pemakai memori.
3. Jalankan menu **3** untuk meninjau kandidat service. Jangan menganggap semua service dalam daftar harus dimatikan.
4. Jalankan menu **6** untuk memeriksa aplikasi UWP dan izin background.
5. Jalankan menu **13** untuk menyimpan laporan sistem.
6. Terapkan perubahan satu per satu. Mulai dari pengaturan yang paling rendah risikonya; hindari mengubah banyak service sekaligus.
7. Restart bila diminta atau setelah perubahan service/pagefile, lalu tunggu beberapa menit agar aktivitas startup selesai.
8. Bandingkan kembali Available Memory, proses pemakai RAM, CPU, aktivitas disk, dan responsivitas. Jangan menilai hasil hanya dari angka Used RAM.
9. Jika terjadi masalah, gunakan menu **12** untuk memulihkan bagian konfigurasi yang tercakup dalam baseline. Jika Windows mengalami masalah serius, gunakan System Restore atau backup sistem.

## Penyimpanan backup dan log

Direktori default:

```text
C:\ProgramData\Optimasi-Windows-10-Toolkit\
```

Simpan salinan direktori ini sebelum eksperimen lanjutan. Periksa log setelah menjalankan operasi yang mengubah sistem.

## Batasan pemulihan

Baseline toolkit bukan image/backup penuh Windows. Restore hanya mencakup item yang secara eksplisit dicatat, yaitu sebagian pengaturan registry, service yang dikelola toolkit, dan konfigurasi pagefile.

Restore **tidak** membatalkan uninstall aplikasi UWP, mengembalikan installer yang terhapus, memulihkan semua pengaturan startup, scheduled task, driver, aplikasi pihak ketiga, atau perubahan yang dibuat tool lain. Penghapusan Edge juga tidak dipulihkan oleh baseline.

## Prinsip keselamatan

Toolkit tidak dimaksudkan untuk menonaktifkan komponen inti Windows. Jangan menonaktifkan Windows Defender/Windows Security, Windows Update, RPC, DHCP Client, DNS Client, Plug and Play, Task Scheduler, atau service driver/perangkat keras.

- Jangan menonaktifkan pagefile, khususnya pada perangkat RAM 4 GB.
- Jangan menghapus Microsoft Store, framework/runtime, atau Microsoft Edge WebView2.
- Jangan menonaktifkan service hanya berdasarkan nama atau asumsi bahwa service tersebut tidak diperlukan.
- Jangan menggunakan RAM cleaner atau registry cleaner sebagai pengganti diagnosis.
- Uninstall UWP berlaku untuk akun saat ini; kemampuan reinstall bergantung pada ketersediaan paket dan sumber instalasi.
- Uninstall Edge bersifat advanced/eksperimental dan bukan rekomendasi penghematan RAM.
- Pengaturan background UWP tidak menghentikan semua aplikasi desktop atau service pihak ketiga.

Detail tambahan: [docs/SAFETY.md](docs/SAFETY.md).

## Status pengujian

- [ ] Parse check pada Windows PowerShell 5.1.
- [ ] Uji pada Windows 10 Pro 22H2 x64.
- [ ] Uji pada laptop RAM 4 GB dengan integrated GPU/shared memory.
- [ ] Uji baseline dan restore pada VM/snapshot.
- [ ] Uji perubahan service pada beberapa vendor laptop.
- [ ] Uji pembatasan background UWP dan uninstall pada akun uji.
- [ ] Review seluruh perubahan registry dan pagefile.

**Catatan:** CI melakukan validasi statis; status CI bukan bukti bahwa semua fungsi telah aman diuji pada perangkat fisik.

## Roadmap

- [ ] System diagnostics yang lebih lengkap.
- [ ] Realtime CPU/RAM/disk monitor.
- [ ] Memory pressure dan commit analyzer.
- [ ] Startup manager dengan enable/disable dan restore.
- [ ] Scheduled Task audit dengan klasifikasi risiko.
- [ ] GPU/shared memory dan driver diagnostics.
- [ ] SSD health melalui provider yang didukung perangkat.
- [ ] SFC/DISM maintenance assistant.
- [ ] Profil Balanced / Low RAM / Performance dengan backup per profil.
- [ ] Pester tests dan CI linting yang lebih lengkap.
- [ ] Dokumentasi Bahasa Indonesia dan Inggris.

## Kontribusi dan pelaporan masalah

Kontribusi dipersilakan. Baca [CONTRIBUTING.md](CONTRIBUTING.md) sebelum mengirim perubahan. Untuk laporan kerusakan, sertakan versi Windows, versi PowerShell, spesifikasi perangkat, langkah reproduksi, dan log yang sudah disanitasi. Jangan unggah serial number, alamat email, username pribadi, atau informasi sensitif lainnya.

Laporan keamanan: lihat [SECURITY.md](SECURITY.md).

## Lisensi

Proyek ini menggunakan lisensi [MIT](LICENSE).

## Status dukungan Windows 10

Dukungan reguler Windows 10 berakhir pada **14 Oktober 2025**. Toolkit ini tidak memperpanjang dukungan keamanan Windows dan tidak menggantikan pembaruan keamanan. Pertimbangkan opsi Extended Security Updates (ESU) yang memenuhi syarat atau sistem operasi yang masih didukung.

## Referensi

- [Microsoft Learn — about_Execution_Policies (Windows PowerShell 5.1)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1)
