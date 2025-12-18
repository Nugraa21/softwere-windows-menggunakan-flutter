<!-- studi kasus 

no | nama | nip | jenis absen     | waktu absen masuk | absen masuk| waktu pulang | absen pulang | keterangan                | 
1  | n    |111  | absen biasa     | 08:00             | mausk      | 01:00        | pulang       | di setujui                |
2  | l    |010  | absen biasa     | 02:00             | pulang     |              |              | sangsi 3 jam tidak masuk  |
3  | q    |013  | izin            |                   |            |              |              | sakit / dari inputan form |	             
4  | e    |142  | penugasan       | 08:00 	      | masuk      | 03:00        | pulang       | di terima / di tolak      |
5  | h    |122  | penugasan full  |                   |            |              |              | di terima / di tolak      |
6  | v    |178  | pulang cepat    | 08:00             | mausk      | 09:00        | pulang cepat | di terima / di tolak      |




penutupan absen masuk max telat jam 09:00
pembukaan absen pulang minimal jam 01:00
untuk pulang cepat tidak menghiraukan jam ( konfirmasi di setujui / tidak )
untuk izin 
penugasan pulang / masuk jam nya tidak perlu soalnya jam nya ada di dalam informasi surat tugasnya , sana yabg penugasan full 

 -->
# Studi Kasus Sistem Absensi


## Tabel rekap harian

| No | Nama | NIP | Jenis Absen    | Waktu Absen Masuk | Absen Masuk | Waktu Pulang | Absen Pulang | Keterangan                         |
|----|------|-----|----------------|-------------------|-------------|--------------|--------------|------------------------------------|
| 1  | n    | 111 | absen biasa    | 08:00             | masuk       | 01:00        | pulang       | di setujui                         |
| 2  | l    | 010 | absen biasa    | 02:00             | pulang      |              |              | sangsi 3 jam tidak masuk           |
| 3  | q    | 013 | izin           |                   |             |              |              | sakit / dari inputan form          |
| 4  | e    | 142 | penugasan      | 08:00             | masuk       | 03:00        | pulang       | di terima / di tolak               |
| 5  | h    | 122 | penugasan full |                   |             |              |              | di terima / di tolak               |
<!-- | 6  | v    | 178 | pulang cepat   | 08:00             | masuk       | 09:00        | pulang cepat | di terima / di tolak               | -->

## Aturan Sistem Absensi
- **Penutupan absen masuk**: Maksimal telat jam 09:00.
- **Pembukaan absen pulang**: Minimal jam 01:00.
- **Pulang cepat**: Tidak menghiraukan jam (konfirmasi di setujui / tidak).
- **Izin**: Ditangani secara khusus berdasarkan inputan form (misalnya, sakit).
- **Penugasan**: Jam pulang/masuk tidak perlu diisi karena jamnya ada di dalam informasi surat tugasnya. Khusus penugasan full, tidak ada kolom jam yang diisi.
- Untuk logi jadi bisa pakai username/ nip nik 
- menambahkan untuk menghapus absensi 

## Catatan 
- untun absen masuk dan pulang biasa itu ada hal beru jadi kalau lupa melakukan absen sala satunya contoh lupa masuk / pulang bakal kena sangsi (3 jam tidak masuk)
-  rekap untuk bagian harian tambahkan rentan waktu mau pilih dari waktu wal sampai akhir 



## Catatan perbaruan 
- untuk informasi user ada (username,nama langkap,nip/mik (karyawan tidak perlu ini),guru/karyawa,password,device id)
- untuk username sama password itu defauld jadi menu register di hapus jadi username sama password itu admin yang memasukan 
- jadi tampilan users ada menu baru untuk edit (password saja)
- untuk device id otomatis masuk saat user login dengan username password awal jadi awal login di hp langsung device id nya keditek gitu masukin ke database 
<!-- 
### sql awal
```sql
DROP TABLE IF EXISTS absensi;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS login_tokens;

CREATE TABLE users (
  id INT(11) NOT NULL AUTO_INCREMENT,
  username VARCHAR(255) NOT NULL,
  nama_lengkap VARCHAR(255) NOT NULL,
  nip_nik VARCHAR(255) DEFAULT NULL,  -- Optional untuk karyawan (validated di PHP/Flutter), required untuk guru
  type ENUM('karyawan', 'guru') NOT NULL,  -- Kolom baru: Membedakan jenis user (karyawan atau guru), wajib diisi saat insert
  password VARCHAR(255) NOT NULL,
  role ENUM('user','admin','superadmin') DEFAULT 'user',
  device_id VARCHAR(255) DEFAULT NULL,  -- Nullable untuk admin/superadmin; UNIQUE untuk user
  PRIMARY KEY (id),
  UNIQUE KEY unique_username (username),
  UNIQUE KEY unique_device (device_id),  -- Memungkinkan multiple NULL (untuk admin)
  INDEX idx_type_nip (type, nip_nik)  -- Index opsional untuk query cepat berdasarkan type dan NIP
);

CREATE TABLE absensi (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  jenis ENUM('Masuk','Pulang','Izin','Pulang Cepat','Penugasan_Masuk','Penugasan_Pulang','Penugasan_Full'),
  keterangan TEXT,
  informasi TEXT,  -- For Penugasan details (wajib)
  dokumen VARCHAR(255),  -- Path to uploaded dokumen (wajib for Penugasan)
  selfie VARCHAR(255),
  latitude VARCHAR(100),
  longitude VARCHAR(100),
  status ENUM('Pending','Disetujui','Ditolak') DEFAULT 'Pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ================== sementara aja
CREATE TABLE login_tokens (
    user_id INT PRIMARY KEY,
    token VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

``` -->
### sql awal 
```sql
DROP TABLE IF EXISTS absensi;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS login_tokens;

CREATE TABLE users (
  id INT(11) NOT NULL AUTO_INCREMENT,
  username VARCHAR(255) NOT NULL,
  nama_lengkap VARCHAR(255) NOT NULL,
  nip_nik VARCHAR(255) DEFAULT NULL,  -- Optional untuk karyawan (validated di PHP/Flutter), required untuk guru
  type ENUM('karyawan', 'guru') NOT NULL,  -- Membedakan jenis user (karyawan atau guru), wajib diisi saat insert
  password VARCHAR(255) NOT NULL,
  role ENUM('user','admin','superadmin') DEFAULT 'user',
  device_id VARCHAR(255) DEFAULT NULL,  -- Nullable untuk admin/superadmin; UNIQUE untuk user
  PRIMARY KEY (id),
  UNIQUE KEY unique_username (username),
  UNIQUE KEY unique_device (device_id),  -- Memungkinkan multiple NULL (untuk admin)
  INDEX idx_type_nip (type, nip_nik)  -- Index opsional untuk query cepat berdasarkan type dan NIP
);

CREATE TABLE absensi (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  jenis ENUM('Masuk','Pulang','Izin','Pulang Cepat','Penugasan_Masuk','Penugasan_Pulang','Penugasan_Full') NOT NULL,
  waktu_absen TIME,  -- Waktu spesifik absen (e.g., '08:00'), wajib untuk Masuk/Pulang/Pulang Cepat; opsional untuk Izin/Penugasan (dari surat tugas)
  tanggal DATE DEFAULT (CURDATE()),  -- Tanggal absen, default hari ini untuk grouping rekap harian/bulanan
  keterangan TEXT,  -- Keterangan umum (e.g., 'sakit' untuk Izin, 'di setujui' untuk approval)
  informasi TEXT,  -- Detail Penugasan (wajib untuk Penugasan_* types, berisi jam dari surat tugas)
  dokumen VARCHAR(255),  -- Path to uploaded dokumen (wajib untuk Penugasan_* dan Izin jika ada bukti)
  selfie VARCHAR(255),  -- Path to selfie photo (opsional, untuk verifikasi)
  latitude DECIMAL(10, 8),  -- Latitude lokasi (presisi lebih baik daripada VARCHAR)
  longitude DECIMAL(11, 8), -- Longitude lokasi (presisi lebih baik daripada VARCHAR)
  status ENUM('waiting','Disetujui','Ditolak') DEFAULT 'waiting',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_date (user_id, tanggal),  -- Index untuk rekap cepat per user dan tanggal/bulan
  INDEX idx_jenis_status (jenis, status),   -- Index untuk filter jenis dan status (e.g., query approval)
  CHECK (waktu_absen IS NOT NULL OR jenis IN ('Izin', 'Penugasan_Full'))  -- Constraint: waktu_absen wajib kecuali Izin/Penugasan_Full
);

-- ================== sementara aja
CREATE TABLE login_tokens (
    user_id INT PRIMARY KEY,
    token VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

## login username / nik nip 
```sql
DROP TABLE IF EXISTS absensi;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS login_tokens;

CREATE TABLE users (
  id INT(11) NOT NULL AUTO_INCREMENT,
  username VARCHAR(255) NOT NULL,
  nama_lengkap VARCHAR(255) NOT NULL,
  nip_nik VARCHAR(255) DEFAULT NULL,  -- Optional untuk karyawan (validated di PHP/Flutter), required untuk guru; UNIQUE untuk login via NIP
  type ENUM('karyawan', 'guru') NOT NULL,  -- Membedakan jenis user (karyawan atau guru), wajib diisi saat insert
  password VARCHAR(255) NOT NULL,
  role ENUM('user','admin','superadmin') DEFAULT 'user',
  device_id VARCHAR(255) DEFAULT NULL,  -- Nullable untuk admin/superadmin; UNIQUE untuk user
  PRIMARY KEY (id),
  UNIQUE KEY unique_username (username),
  UNIQUE KEY unique_nip_nik (nip_nik),  -- UNIQUE untuk NIP/NIK agar unik dan mudah query login (multiple NULL allowed)
  UNIQUE KEY unique_device (device_id),  -- Memungkinkan multiple NULL (untuk admin)
  INDEX idx_type_nip (type, nip_nik)  -- Index opsional untuk query cepat berdasarkan type dan NIP
);

CREATE TABLE absensi (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  jenis ENUM('Masuk','Pulang','Izin','Pulang Cepat','Penugasan_Masuk','Penugasan_Pulang','Penugasan_Full') NOT NULL,
  waktu_absen TIME,  -- Waktu spesifik absen (e.g., '08:00'), wajib untuk Masuk/Pulang/Pulang Cepat; opsional untuk Izin/Penugasan (validasi di app)
  tanggal DATE DEFAULT (CURDATE()),  -- Tanggal absen, default hari ini untuk grouping rekap harian/bulanan
  keterangan TEXT,  -- Keterangan umum (e.g., 'sakit' untuk Izin, 'di setujui' untuk approval)
  informasi TEXT,  -- Detail Penugasan (wajib untuk Penugasan_* types, berisi jam dari surat tugas)
  dokumen VARCHAR(255),  -- Path to uploaded dokumen (wajib untuk Penugasan_* dan Izin jika ada bukti)
  selfie VARCHAR(255),  -- Path to selfie photo (opsional, untuk verifikasi)
  latitude DECIMAL(10, 8),  -- Latitude lokasi (presisi lebih baik daripada VARCHAR)
  longitude DECIMAL(11, 8), -- Longitude lokasi (presisi lebih baik daripada VARCHAR)
  status ENUM('Pending','Disetujui','Ditolak') DEFAULT 'Pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_date (user_id, tanggal),  -- Index untuk rekap cepat per user dan tanggal/bulan
  INDEX idx_jenis_status (jenis, status)  -- Index untuk filter jenis dan status (e.g., query approval)
  -- NOTE: Hapus CHECK constraint untuk kompatibilitas MySQL lama; validasi waktu_absen di PHP/Flutter
);

-- ================== sementara aja
CREATE TABLE login_tokens (
    user_id INT PRIMARY KEY,
    token VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```
### insert data ke database 
```sql
-- Insert Admin Biasa
INSERT INTO users (username, nama_lengkap, nip_nik, type, password, role, device_id) 
VALUES ('prasetyo', 'Prasetyo Admin', NULL, 'karyawan', '081328', 'admin', NULL);

-- Insert Superadmin
INSERT INTO users (username, nama_lengkap, nip_nik, type, password, role, device_id) 
VALUES ('nugra', 'Nugra Super', NULL, 'karyawan', '081328', 'superadmin', NULL);
```