# Optimasi Windows 10 Toolkit

Toolkit berbasis **Windows PowerShell 5.1** untuk membantu pengguna laptop/PC dengan sumber daya terbatas menganalisis penggunaan RAM dan mengelola sebagian beban latar belakang Windows 10.

> **Status pengujian:** Fitur menu **1–21 telah diuji langsung oleh pengguna dan dilaporkan berjalan lancar**. Fitur menu **22 (Restart paksa) belum dikonfirmasi pengujiannya**. Proyek tetap perlu diuji pada perangkat dan konfigurasi Windows lain. Buat System Restore Point, backup data penting, dan pahami dampak setiap perubahan sebelum menjalankan fitur yang mengubah konfigurasi Windows.

## Tujuan proyek

- Mengidentifikasi proses, service, aplikasi UWP, dan program startup yang menggunakan sumber daya.
- Mengurangi beban latar belakang secara selektif, bukan melakukan debloat agresif.
- Menyediakan pencatatan baseline untuk sebagian pengaturan agar perubahan tertentu dapat dipulihkan.
- Memprioritaskan stabilitas, keamanan, dan responsivitas sistem dibanding mengejar angka RAM idle tertentu.

Toolkit ini **tidak dapat menambah kapasitas RAM fisik** dan tidak menjamin angka penggunaan RAM tertentu. Hasil bergantung pada edisi Windows, driver, aplikasi, layanan vendor, dan kondisi perangkat.

## Fitur dan fungsi menu

Script utama: `scripts/Optimasi-Windows-10-Toolkit.ps1`

| Nomor | Tampilan menu | Keterangan |
|---:|---|---|
| 1 | RAM - Lihat penggunaan memori komputer | Menampilkan kapasitas RAM, RAM terpakai, dan RAM tersedia. |
| 2 | Layanan Aktif - Lihat layanan Windows yang berjalan | Menampilkan daftar layanan Windows yang sedang berjalan. |
| 3 | Layanan Opsional - Lihat layanan yang bisa diatur | Menampilkan layanan opsional beserta status dan keterangannya. |
| 4 | Nonaktifkan Layanan - Matikan layanan yang tidak dipakai | Menonaktifkan layanan opsional yang dipilih. Pastikan fiturnya memang tidak digunakan. |
| 5 | Mode Manual - Atur layanan agar berjalan saat dibutuhkan | Mengubah jenis startup layanan terpilih menjadi Manual. |
| 6 | Aplikasi UWP - Lihat aplikasi bawaan Windows | Menampilkan aplikasi UWP dan pengaturan aktivitas latar belakangnya. |
| 7 | Aplikasi Latar - Atur aplikasi yang berjalan di latar belakang | Mengubah izin aplikasi latar yang didukung untuk akun saat ini. |
| 8 | Aplikasi Startup - Lihat aplikasi saat komputer dinyalakan | Menampilkan program startup yang terdeteksi. |
| 9 | Pemakai RAM - Cari proses yang menggunakan banyak memori | Mengurutkan kelompok proses berdasarkan penggunaan RAM. |
| 10 | Optimasi - Terapkan pengaturan Windows yang lebih ringan | Menerapkan pengaturan terbatas untuk aplikasi latar, Game DVR, visual effects, dan pagefile. |
| 11 | Memori Virtual Otomatis - Gunakan pengaturan otomatis Windows | Mengaktifkan pengelolaan pagefile otomatis oleh Windows. |
| 12 | Pulihkan Pengaturan - Kembalikan pengaturan dari backup | Memulihkan pengaturan yang tercatat di baseline toolkit. |
| 13 | Laporan Sistem - Simpan informasi kondisi komputer | Mengekspor ringkasan informasi sistem untuk troubleshooting. |
| 14 | Backup dan Log - Buka folder cadangan dan catatan | Membuka folder penyimpanan baseline dan log toolkit. |
| 15 | Daftar Aplikasi - Lihat aplikasi bawaan yang bisa dihapus | Menampilkan kandidat aplikasi UWP konsumen yang dapat dievaluasi. |
| 16 | Hapus Aplikasi - Hapus aplikasi UWP yang dipilih | Menghapus aplikasi terpilih untuk akun pengguna saat ini. |
| 17 | Cek Edge dan WebView2 - Periksa komponen browser Microsoft | Memeriksa keberadaan Microsoft Edge dan WebView2 Runtime. |
| 18 | Kesehatan Windows - Periksa RAM dan layanan penting | Menampilkan RAM, layanan inti, status Defender jika tersedia, dan proses pemakai RAM tertinggi. |
| 19 | Hapus Edge - Hapus browser dan nonaktifkan update Edge | Menjalankan uninstaller Edge, menghentikan/menonaktifkan layanan Edge Update, dan menonaktifkan Scheduled Tasks Edge Update setelah konfirmasi. WebView2 dan file updater bersama dipertahankan. |
| 20 | Atur Memori Virtual SSD - Atur ukuran pagefile di SSD | Mengatur pagefile tetap pada C: setelah pemeriksaan SSD, ruang kosong, dan konfirmasi. Restart diperlukan. |
| 21 | Alat Tambahan - Buka fitur diagnosis lainnya | Membuka submenu diagnosis, termasuk pemeriksaan `svchost.exe` dan layanan terkait. |
| 22 | Restart - Restart paksa komputer | Memulai ulang komputer dan memaksa aplikasi menutup setelah konfirmasi `RESTART FORCE`. Data yang belum disimpan dapat hilang. |
| 23 | Windows Update - Nonaktifkan atau pulihkan update otomatis | Menonaktifkan kebijakan update otomatis dan layanan Windows Update/Update Orchestrator setelah konfirmasi; dapat dipulihkan dari snapshot konfigurasi awal. |
| 0 | Keluar - Tutup program | Menutup toolkit. |

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


### Windows Update (menu 23)

- Pilihan **1** menonaktifkan update otomatis melalui kebijakan `NoAutoUpdate`, lalu mencoba menghentikan dan menonaktifkan layanan `wuauserv` (Windows Update) serta `UsoSvc` (Update Orchestrator).
- Sebelum perubahan, kondisi awal nilai registry, startup type, dan status kedua layanan disimpan ke `C:\ProgramData\Optimasi-Windows-10-Toolkit\windows-update-backup.json`.
- Konfirmasi wajib: `DISABLE WINDOWS UPDATE`. Fitur ini tidak menonaktifkan `WaaSMedicSvc` dan tidak mengubah Windows Defender.
- Pilihan **2** memulihkan nilai registry, startup type, dan status layanan dari backup dengan konfirmasi `RESTORE WINDOWS UPDATE`.
- Windows Update Medic/servicing Windows dapat mengaktifkan kembali layanan pada kondisi tertentu. Hak akses atau proteksi Windows juga dapat menolak perubahan layanan; periksa hasil yang ditampilkan, jangan menganggap semua komponen berhasil dinonaktifkan.
- **Risiko keamanan:** selama update otomatis dimatikan, Windows tidak menerima patch keamanan dan perbaikan otomatis. Gunakan hanya sementara, cek pembaruan secara manual, dan pulihkan konfigurasi setelah kebutuhan selesai.
- Fitur ini belum diuji langsung pada perangkat Windows fisik. Backup fitur ini terpisah dari menu 12 (baseline).
### Restart paksa Windows (menu 22)

- Menu ini menjalankan `shutdown.exe /r /f /t 0` setelah pengguna mengetik `RESTART FORCE`.
- Parameter `/f` memaksa aplikasi menutup dan dapat menyebabkan data yang belum disimpan hilang. Simpan pekerjaan terlebih dahulu.
- Jangan gunakan sebagai pengganti restart normal bila aplikasi masih memiliki pekerjaan terbuka.

### Cek RAM svchost.exe (menu 21 → 1)

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
- Batas input adalah 1.000-24.000 MB. Deteksi SSD menggunakan `Get-Disk.MediaType`, `Get-PhysicalDisk.MediaType`, dan identitas model `Win32_DiskDrive`. Jika salah satu sumber secara eksplisit menunjukkan HDD, proses ditolak. Jika semua sumber hanya melaporkan `Unspecified`/tidak tersedia (umum pada sebagian SSD SATA/AHCI), toolkit menampilkan model dan bus lalu meminta konfirmasi fisik dengan mengetik `CONFIRM SSD`. Bus SATA saja tidak dianggap bukti SSD; konfirmasi manual menjadi tanggung jawab pengguna.
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

Toolkit tidak menganjurkan penonaktifan permanen komponen inti Windows. Jangan menonaktifkan Windows Defender/Windows Security, RPC, DHCP Client, DNS Client, Plug and Play, Task Scheduler, atau service driver/perangkat keras. Menu 23 menyediakan kontrol Windows Update secara opsional dan sementara dengan peringatan risiko keamanan serta fitur pemulihan.

- Jangan menonaktifkan pagefile, khususnya pada perangkat RAM 4 GB.
- Jangan menghapus Microsoft Store, framework/runtime, atau Microsoft Edge WebView2.
- Paket Appx dengan `NonRemovable=True`, termasuk `Microsoft.XboxGameCallableUI` bila ditandai demikian pada sistem, tidak dimasukkan ke katalog uninstall. Itu adalah komponen sistem; jangan memaksa penghapusannya.
- Jangan menonaktifkan service hanya berdasarkan nama atau asumsi bahwa service tersebut tidak diperlukan.
- Jangan menggunakan RAM cleaner atau registry cleaner sebagai pengganti diagnosis.
- Uninstall UWP berlaku untuk akun saat ini; kemampuan reinstall bergantung pada ketersediaan paket dan sumber instalasi.
- Menu 19 menjalankan uninstaller `setup.exe` Edge, menghentikan dan menonaktifkan layanan `edgeupdate`, `edgeupdatem`, serta `MicrosoftEdgeElevationService` bila tersedia, lalu menonaktifkan Scheduled Tasks pada folder `\Microsoft\EdgeUpdate\`. Konfirmasi wajib: `REMOVE EDGE AND UPDATE`.
- Menu 19 tidak menghapus service secara permanen, file updater bersama, registry updater, atau WebView2 Runtime. Service dan task dinonaktifkan agar updater tidak berjalan otomatis; snapshot kondisi awal disimpan di `C:\ProgramData\Optimasi-Windows-10-Toolkit\edge-update-backup.json`.
- Jika WebView2 terpasang, menonaktifkan Edge Update juga menghentikan pembaruan keamanan otomatis WebView2. Aplikasi lain dapat bergantung pada WebView2; pertahankan runtime tersebut dan pahami konsekuensi update sebelum melanjutkan.
- Uninstall Edge tidak didukung pada semua build/region/kebijakan Windows. Jika Edge tetap terdeteksi setelah proses, periksa hasil menu 17, log toolkit, dan kebijakan perangkat. Baseline tidak dapat memulihkan Edge atau status Edge Update; siapkan installer resmi dan catat status awal sebelum menjalankan fitur.
- Pengaturan background UWP tidak menghentikan semua aplikasi desktop atau service pihak ketiga.

Detail tambahan: [docs/SAFETY.md](docs/SAFETY.md).

## Status pengujian

- [x] Fitur menu **1–21** telah diuji langsung oleh pengguna; seluruhnya dilaporkan berjalan lancar.
- [ ] Menu **22 — Restart paksa** belum dikonfirmasi pengujiannya. Fitur ini menutup aplikasi tanpa dialog penyimpanan dan berisiko menghilangkan data yang belum disimpan.
- [ ] Menu **23 — Windows Update** belum diuji langsung pada perangkat fisik. Verifikasi penghentian layanan, kebijakan, dan pemulihan pada VM/snapshot sebelum penggunaan rutin.
- [x] Validasi parser Windows PowerShell 5.1 dan PowerShell 7 pada GitHub Actions.
- [x] Pemeriksaan PSScriptAnalyzer pada GitHub Actions.
- [ ] Uji lintas perangkat dan vendor laptop.
- [ ] Uji baseline dan restore pada VM/snapshot serta matriks konfigurasi Windows yang lebih luas.

**Catatan:** Hasil uji menu 1–21 berasal dari pengujian pengguna. CI hanya memvalidasi parser dan analisis statis; CI bukan bukti bahwa seluruh fungsi telah diuji pada perangkat fisik atau kompatibel dengan semua konfigurasi.

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

## Dukungan anda berarti bagi saya untuk mengembangkan dan menemukan lebih banyak inspirasi.

[Traktir Eki Segelas Kopi](https://app.midtrans.com/payment-links/b45ec2c9-80f7-4dd8-b2e9-e18d430d192e-7l5NTR4t)

<a href="https://app.midtrans.com/payment-links/b45ec2c9-80f7-4dd8-b2e9-e18d430d192e-7l5NTR4t">
  <img src="./G025119549_Payment_Link_b45ec2c9-80f7-4dd8-b2e9-e18d430d192e-7l5NTR4t.png" alt="QR Traktir Eki Segelas Kopi" width="320" />
</a>
