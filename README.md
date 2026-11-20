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
| 1 | Ringkasan RAM | Menampilkan informasi memori fisik dan penggunaan RAM saat ini. |
| 2 | Service aktif | Menampilkan daftar service Windows yang sedang berjalan untuk audit. |
| 3 | Service opsional | Menampilkan kandidat service yang dapat dievaluasi berdasarkan kebutuhan perangkat. |
| 4 | Nonaktifkan service | Menonaktifkan service opsional yang dipilih secara manual. Gunakan hanya jika memahami dampaknya. |
| 5 | Set service Manual | Mengubah startup type service terpilih menjadi Manual, sebagai alternatif yang lebih konservatif daripada Disabled. |
| 6 | Aplikasi UWP | Menampilkan aplikasi UWP dan informasi pengaturan aktivitas background yang dapat dibaca. |
| 7 | Atur background UWP | Mengubah izin background untuk aplikasi yang didukung pada akun pengguna saat ini. Tidak mengendalikan semua aplikasi desktop. |
| 8 | Aplikasi startup | Menampilkan program startup yang terdeteksi melalui WMI/CIM. |
| 9 | Proses pemakai RAM | Mengelompokkan proses berdasarkan nama dan menjumlahkan Working Set; menandai kelompok di atas 250 MB untuk diperiksa dan 500 MB sebagai tinggi. Ambang ini indikatif, bukan diagnosis malware. |
| 10 | Optimasi aman | Menerapkan pengaturan terbatas terkait aplikasi background, Game DVR, visual effects, dan pagefile. Menampilkan jumlah tindakan berhasil, persentase tindakan sukses, serta perubahan estimasi RAM terpakai sebelum/sesudah. |

| 11 | Pagefile otomatis | Mengaktifkan pengelolaan pagefile otomatis oleh Windows. Disarankan untuk perangkat dengan RAM terbatas; jangan menonaktifkan pagefile. |
| 12 | Pulihkan baseline | Memulihkan pengaturan registry, service yang dicatat, dan konfigurasi pagefile dari baseline yang dibuat toolkit. Bukan full system restore. |
| 13 | Laporan sistem | Mengekspor ringkasan informasi sistem untuk kebutuhan troubleshooting. |
| 14 | Folder backup dan log | Membuka direktori penyimpanan baseline dan log toolkit. |
| 15 | Katalog aplikasi bawaan | Menampilkan kandidat aplikasi UWP konsumen yang dapat dievaluasi sebelum uninstall. |
| 16 | Hapus aplikasi UWP | Menghapus aplikasi yang dipilih untuk akun pengguna saat ini. Backup baseline tidak menyimpan installer dan tidak dapat memasang ulang aplikasi. |
| 17 | Audit Edge / WebView2 | Memeriksa keberadaan Microsoft Edge dan WebView2 Runtime. |
| 18 | Kesehatan sistem | Menampilkan RAM saat ini, status service inti, status Microsoft Defender jika dapat dibaca, dan 10 kelompok proses dengan RAM tertinggi. |
| 19 | Hapus Microsoft Edge | Menjalankan uninstaller bawaan Edge setelah konfirmasi eksplisit. Tidak menghapus WebView2 dan tidak dijamin tersedia/berhasil pada semua build atau kebijakan Windows. Tidak dapat dipulihkan oleh baseline. |
| 20 | Atur pagefile SSD | Mengatur pagefile tetap 1.000-24.000 MB hanya pada C: setelah memverifikasi disk C sebagai SSD, ruang kosong, menampilkan konfigurasi lama, dan meminta konfirmasi eksplisit. Pagefile pada partisi lain dihapus dari konfigurasi. Restart diperlukan. |
| 21 | Tools tambahan | Membuka submenu diagnostik, termasuk pemeriksaan RAM `svchost.exe`, PID, layanan, dan lokasi executable. Pemeriksaan bersifat read-only. |
| 22 | Restart paksa Windows | Memulai ulang Windows dan memaksa aplikasi menutup setelah konfirmasi `RESTART FORCE`. Aplikasi yang belum menyimpan data akan kehilangan perubahan. |
| 0 | Keluar | Menutup toolkit. |

## Persyaratan

- Windows 10 22H2 x64 (target pengembangan; kompatibilitas edisi lain belum diuji).
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
3. Ekstrak seluruh ZIP ke folder yang mudah diakses, misalnya `C:\Tools\Optimasi-Win-10-Toolkit`. Pertahankan struktur folder agar launcher dapat menemukan script PowerShell.

### Jalankan toolkit (direkomendasikan)

1. Ekstrak seluruh repository; jangan memindahkan file BAT terpisah dari folder `scripts`.
2. Jalankan `Optimasi-Win-10-Toolkit.bat` dengan double-click. Jika belum berjalan sebagai Administrator, launcher meminta persetujuan UAC secara otomatis.
3. Alternatifnya, klik kanan file BAT lalu pilih **Run as administrator**.
4. Setelah UAC disetujui, launcher menjalankan script melalui Windows PowerShell 5.1.

Launcher menggunakan `-ExecutionPolicy Bypass` hanya untuk proses PowerShell toolkit. Kebijakan eksekusi sistem tidak diubah secara permanen. Jika UAC dibatalkan, toolkit tidak dijalankan.

### Jalankan langsung melalui PowerShell (opsional)

Buka **Windows PowerShell 5.1** sebagai Administrator, lalu jalankan:

```powershell
Set-Location "C:\Tools\Optimasi-Win-10-Toolkit"
.\scripts\Optimasi-Windows-10-Toolkit.ps1
```

Jika file diblokir oleh Windows, periksa sumber dan isi file terlebih dahulu. Setelah yakin file tepercaya, buka blokir file secara spesifik:

```powershell
Unblock-File .\scripts\Optimasi-Windows-10-Toolkit.ps1
```

Jangan mengubah Execution Policy menjadi `Unrestricted` atau mengubah kebijakan keamanan secara permanen hanya untuk menjalankan toolkit. Kebijakan Group Policy organisasi dapat tetap membatasi eksekusi script.
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
10. Gunakan menu **22** hanya jika memang perlu restart paksa. Simpan semua pekerjaan terlebih dahulu karena aplikasi akan ditutup tanpa dialog penyimpanan.


### Restart paksa Windows (menu 22)

- Menu ini menjalankan `shutdown.exe /r /f /t 0` setelah pengguna mengetik `RESTART FORCE`.
- Parameter `/f` memaksa aplikasi menutup dan dapat menyebabkan data yang belum disimpan hilang. Simpan pekerjaan terlebih dahulu.
- Jangan gunakan sebagai pengganti restart normal bila aplikasi masih memiliki pekerjaan terbuka.

### Pemeriksaan svchost.exe (menu 21 → 1)

- Daftar proses `svchost.exe` diurutkan berdasarkan Working Set dan menampilkan PID, RAM (MB), jumlah layanan, nama layanan, serta penanda indikatif.
- Masukkan PID untuk melihat executable path, command line, dan rincian nama layanan, display name, status, serta startup type.
- Ambang `>=250 MB` adalah PERIKSA dan `>=500 MB` adalah TINGGI. Ambang hanya membantu menentukan prioritas pemeriksaan; bukan bukti malware atau kerusakan.
- Satu proses `svchost.exe` dapat menampung beberapa layanan Windows. Konsumsi RAM harus ditelusuri ke layanan dan aktivitas terkait, bukan dengan menghentikan proses host.
- Pemeriksaan ini read-only dan tidak menghentikan proses, mengubah startup type, atau menonaktifkan layanan.

### Membaca laporan RAM dan hasil optimasi

- Persentase sukses adalah jumlah tindakan konfigurasi yang berhasil dibagi jumlah tindakan yang dicoba. Ini **bukan** persentase peningkatan performa.
- Perubahan RAM dihitung dari estimasi RAM terpakai tepat sebelum dan sesudah menu 10. Proses latar belakang, cache, dan aktivitas Windows dapat mengubah angka tersebut; hasil bukan bukti pasti RAM telah dibebaskan oleh toolkit.
- Menu 18 memeriksa service inti yang dipilih. Status **OK** hanya berarti service yang diperiksa memenuhi pemeriksaan sederhana, bukan sertifikasi keamanan seluruh Windows.
- Daftar RAM dikelompokkan berdasarkan nama proses agar beberapa instance browser/aplikasi tidak tersebar menjadi banyak baris. Working Set dapat menghitung shared memory lebih dari sekali.


### Custom Virtual Memory / Pagefile (menu 20)

- Masukkan ukuran dalam MB, misalnya `4000` untuk pagefile tetap 4.000 MB. Initial Size dan Maximum Size dibuat sama.
- Batas input adalah 1.000-24.000 MB. Fitur hanya berjalan jika Windows melaporkan disk fisik di belakang drive C sebagai `SSD`. Jika `HDD` atau `Unspecified`, proses dibatalkan; perangkat RAID/Storage Controller yang tidak melaporkan jenis media secara jelas harus diverifikasi manual.
- Lokasi yang dibuat adalah `C:\\pagefile.sys`. Semua konfigurasi pagefile manual yang ada pada partisi lain akan dihapus agar hanya C: yang dikonfigurasi.
- Fitur memerlukan ruang kosong C: minimal sebesar ukuran pagefile ditambah cadangan 2.048 MB.
- Sebelum perubahan, toolkit menampilkan disk, tipe media, ruang kosong, dan konfigurasi pagefile saat ini. Pengguna harus mengetik `SET PAGEFILE` untuk melanjutkan.
- Baseline yang ada digunakan untuk pemulihan; jika belum ada, baseline dibuat sebelum perubahan. Jika proses gagal di tengah jalan, toolkit mencoba memulihkan konfigurasi sebelumnya secara otomatis. Menu 12 tetap menjadi jalur pemulihan baseline.
- Restart diperlukan agar konfigurasi aktif. Pagefile memperbesar commit limit, bukan kapasitas RAM fisik atau kecepatan RAM. Jangan menetapkan ukuran besar tanpa kebutuhan dan ruang disk yang cukup.
- Ukuran pagefile ideal tidak universal; pertimbangkan peak commit, crash dump, beban aplikasi, dan ruang disk. System Managed (menu 11) tetap pilihan default yang lebih aman untuk kebanyakan pengguna.

## Penyimpanan backup dan log

Direktori default:

```text
C:\ProgramData\Optimasi-Windows-10-Toolkit\
```

Simpan salinan direktori ini sebelum eksperimen lanjutan. Periksa log setelah menjalankan operasi yang mengubah sistem.

## Batasan pemulihan

Baseline toolkit bukan image/backup penuh Windows. Restore hanya mencakup item yang secara eksplisit dicatat, yaitu sebagian pengaturan registry, service yang dikelola toolkit, status pagefile otomatis, serta ukuran dan lokasi pagefile manual yang berhasil dibaca saat baseline dibuat.

Restore **tidak** membatalkan uninstall aplikasi UWP, mengembalikan installer yang terhapus, memulihkan semua pengaturan startup, scheduled task, driver, aplikasi pihak ketiga, atau perubahan yang dibuat tool lain. Penghapusan Edge juga tidak dipulihkan oleh baseline.

## Prinsip keselamatan

Toolkit tidak dimaksudkan untuk menonaktifkan komponen inti Windows. Jangan menonaktifkan Windows Defender/Windows Security, Windows Update, RPC, DHCP Client, DNS Client, Plug and Play, Task Scheduler, atau service driver/perangkat keras.

- Jangan menonaktifkan pagefile, khususnya pada perangkat RAM 4 GB.
- Jangan menghapus Microsoft Store, framework/runtime, atau Microsoft Edge WebView2.
- Paket Appx dengan `NonRemovable=True`, termasuk `Microsoft.XboxGameCallableUI` bila ditandai demikian pada sistem, tidak dimasukkan ke katalog uninstall. Itu adalah komponen sistem; jangan memaksa penghapusannya.
- Jangan menonaktifkan service hanya berdasarkan nama atau asumsi bahwa service tersebut tidak diperlukan.
- Jangan menggunakan RAM cleaner atau registry cleaner sebagai pengganti diagnosis.
- Uninstall UWP berlaku untuk akun saat ini; kemampuan reinstall bergantung pada ketersediaan paket dan sumber instalasi.
- Menu 19 menyediakan uninstall Edge tingkat lanjut melalui `setup.exe` bawaan Edge dengan konfirmasi `UNINSTALL EDGE`. Fitur ini berisiko, tidak dijamin pada semua build/region, dan tidak menghapus WebView2. Baseline toolkit tidak dapat memulihkan Edge; siapkan installer resmi untuk memasangnya kembali jika diperlukan.
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
