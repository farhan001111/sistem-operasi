# Sistem Backup Lokal (`backup.sh`)

UAS Praktikum Sistem Operasi - Lab Sistem Operasi A, Semester 2026.

Script bash untuk membuat backup `.tar.gz` dari sebuah direktori, lengkap dengan
retensi, log, list, restore, menu interaktif, dan penjadwalan lewat crontab.

## Isi folder

| File | Fungsi |
|---|---|
| `backup.sh` | Program utama: baca konfigurasi, opsi CLI, menu, crontab |
| `backup.conf` | File konfigurasi bawaan |
| `backup_function.sh` | Fitur backup (`create_backup`) |
| `retensi_log.sh` | Retensi arsip (`apply_retention`) dan log (`log_line`) |
| `list_restore_function.sh` | List (`do_list`) dan restore (`do_restore`) |

Keempat file `.sh` **harus berada dalam satu folder**, karena `backup.sh`
memuat tiga file lainnya dari folder tempatnya berada.

## Persiapan

```bash
chmod +x backup.sh
```

Tidak perlu `sudo`, jaringan, maupun bahasa selain bash.

## Konfigurasi (`backup.conf`)

```bash
SOURCE="/home/mahasiswa/data-penting"   # direktori sumber (harus ada)
DEST="/home/mahasiswa/backup"           # direktori tujuan (dibuat otomatis)
RETENTION=3                             # jumlah arsip maksimum (bilangan bulat >= 1)
EXCLUDE="*.tmp draft"                   # pola yang tidak diarsipkan (boleh kosong)
CRON="0 2 * * *"                        # jadwal crontab 5 field
```

## Cara menjalankan

```bash
./backup.sh                 # tanpa argumen: menu interaktif
./backup.sh -h              # bantuan
./backup.sh -c FILE         # pakai file konfigurasi lain, lalu backup satu kali
./backup.sh -s SRC          # override SOURCE, lalu backup satu kali
./backup.sh -d DEST         # override DEST, lalu backup satu kali
./backup.sh -l              # daftar arsip (nama dan ukuran)
./backup.sh -r ARSIP        # restore ARSIP ke DEST/restore/
./backup.sh -i              # pasang baris crontab
./backup.sh -U              # hapus baris crontab
```

Opsi data (`-c`, `-s`, `-d`) boleh digabung dengan opsi aksi, contoh:

```bash
./backup.sh -l -d /tmp/dest
./backup.sh -c backup.conf -s /data/proyek -d /tmp/hasil
./backup.sh -r backup_20261115-143005.tar.gz -d /tmp/hasil
```

Aturan mode:
1. Tanpa argumen apa pun: menu interaktif.
2. `-h`, `-l`, `-r`, `-i`, `-U` menentukan aksi.
3. Hanya `-c`, `-s`, `-d` (atau kombinasinya): backup dijalankan satu kali.

## Arsip, log, dan retensi

- Nama arsip: `backup_YYYYMMDD-HHMMSS.tar.gz`, disimpan di `DEST`.
- Isi arsip adalah seluruh isi `SOURCE` (tanpa folder induknya), kecuali pola `EXCLUDE`.
- Log: `DEST/backup.log`, satu baris per aksi dengan format
  `waktu | nama arsip | status`. Status: `SUKSES`, `GAGAL`, atau `HAPUS`
  (arsip lama yang dihapus oleh retensi).
- Setelah backup berhasil, arsip tertua dihapus sampai jumlah arsip `<= RETENTION`.
- Backup gagal (misalnya `SOURCE` tidak ada) tetap dicatat `GAGAL` dan script
  keluar dengan status bukan nol.
- Restore mengekstrak arsip ke `DEST/restore/`. `ARSIP` boleh berupa nama arsip
  (dicari di `DEST`) atau path lengkap.

## Crontab

`-i` memasang tepat satu baris:

```
$CRON /path/absolut/backup.sh -c /path/absolut/backup.conf
```

- Dijalankan ulang tidak menduplikasi baris (baris lama milik script ini diganti).
- `-U` hanya menghapus baris milik script ini, baris crontab lain tidak disentuh.
- `-i` dan `-U` memakai nilai `CRON` dari konfigurasi aktif (ikut terpengaruh `-c`).
- Path memakai path absolut karena cron berjalan dengan environment minim.
- Hindari spasi pada path folder script, karena baris crontab tidak memakai tanda kutip.

## Exit code

`0` hanya jika aksi sukses. Kegagalan (konfigurasi tidak ada, `SOURCE` tidak ada,
arsip tidak ditemukan, opsi tidak dikenal, dan sebagainya) menghasilkan status bukan nol.

## Pengujian

Jalankan contoh pengecekan yang disertakan dosen:

```bash
bash check-sample.sh
```

## Pembagian tugas

| Anggota | Bagian |
|---|---|
| 1 | Program utama, konfigurasi, opsi CLI |
| 2 | Backup `.tar.gz`, nama arsip berdasarkan waktu, exclude |
| 3 | Retensi, log |
| 4 | List dan restore |
| 5 | Menu interaktif, crontab |
| 6 | Integrasi, pengujian, README, laporan, slide |

(Isi nama anggota sesuai kelompok.)
