// ------------------------------- KONFIGURASI BASE URL API --------------------
//
// Informasi Penting:
// 1. baseUrl di bawah menggunakan NGROK → agar API tetap online meski tidak punya server publik.
// 2. NGROK bersifat *sementara*, sehingga URL bisa berubah jika:
//      - Restart komputer
//      - Restart ngrok agent
//      - Token expired
//      - Koneksi internet putus
//
// 3. Solusi agar link NGROK tidak berubah:
//      - Gunakan fitur *Reserved Domain* (berbayar) di Ngrok.
//      - Atau pakai subdomain custom melalui tunnel authtoken.
//      - Atau gunakan reverse proxy / VPS.
//
// 4. Jika menggunakan jaringan lokal (IP), pastikan:
//      - HP & server berada di jaringan yang sama.
//      - IP perangkat server tidak berubah (gunakan IP static).
//
// 5. Jangan commit baseUrl sensitif ke GitHub (gunakan .env + flutter_dotenv).
//
// ------------------------------- NGROK --------------------------------------

const String baseUrl =
    "https://nonlitigious-alene-uninfinitely.ngrok-free.dev/backendapk/";

// -------------------------- BASE URL VIA IP LOCAL ----------------------------
//
// Gunakan ini hanya jika testing di jaringan lokal.
// Pastikan salah satu IP aktif dan benar.
//
// const String baseUrl = "http://192.168.0.101/backendapk/"; // gudang barat
// const String baseUrl = "http://192.168.203.129/backendapk/"; // gudang barat
// const String baseUrl = "http://10.10.70.255/backendapk/";     // gudang barat / smk yk
// const String baseUrl = "http://192.168.137.1/backendapk/";    // smk yk
