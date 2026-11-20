# Contributing

Terima kasih telah membantu meningkatkan Optimasi Windows 10 Toolkit.

## Sebelum mengirim perubahan

- Jelaskan masalah yang ingin diselesaikan.
- Hindari tweak registry/service tanpa bukti dan alasan teknis.
- Jangan menonaktifkan fitur keamanan, Windows Update, jaringan, audio, driver, atau komponen shell inti.
- Semua perubahan sistem harus memiliki konfirmasi, logging, dan strategi restore jika memungkinkan.
- Jangan mengklaim penghematan RAM tertentu tanpa hasil pengujian yang dapat direproduksi.

## Laporan bug

Sertakan:
- Windows edition, version, dan build.
- PowerShell `$PSVersionTable`.
- CPU, RAM terpasang, RAM visible, GPU.
- Langkah reproduksi dan pesan error.
- Log yang sudah menghapus username, serial number, hostname, dan data pribadi.

## Pull request

- Satu perubahan terfokus per pull request.
- Perbarui README dan dokumentasi jika perilaku menu berubah.
- Sertakan hasil parse check PowerShell 5.1.
- Uji backup/restore di mesin virtual atau perangkat cadangan.
