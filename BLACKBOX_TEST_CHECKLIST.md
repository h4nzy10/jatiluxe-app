# Black-Box Testing Checklist — JatiLuxe

Daftar ini digunakan untuk menguji aplikasi **tanpa melihat kode sumber/internal**. Fokusnya adalah input yang dilakukan pengguna dan output yang terlihat di layar (termasuk snackbar, dialog, empty state, dan perubahan data setelah refresh).

## Cara pakai

- Tandai `[ ]` menjadi `[x]` setelah diuji, tuliskan tanggal dan hasil di kolom catatan.
- Jalankan dengan backend lokal (`D:/jatiluxe-api/`) maupun hosted sesuai kebutuhan:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  ```
- Prioritas: **P0** = harus lulus sebelum rilis, **P1** = penting, **P2** = pendukung/edge case.
- Asumsi data: tersedia akun customer, akun seller, dan minimal satu produk dengan stok > 0.

---

## 1. Autentikasi & Sesi

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| AUT-01 | Login dengan email & password benar | Masuk ke navigasi sesuai role (customer/seller) | P0 |
| AUT-02 | Login dengan password salah | Snackbar error, sisa percobaan ditampilkan | P0 |
| AUT-03 | 5 kali gagal berturut-turut | Akun diblokir 30 detik, hitung mundur tampil, login ditolak | P0 |
| AUT-04 | Setelah cooldown, login dengan benar | Berhasil masuk, counter gagal di-reset | P1 |
| AUT-05 | Tutup aplikasi lalu buka lagi | Tetap login (token tersimpan) | P0 |
| AUT-06 | Logout lalu tekan tombol back | Tidak bisa kembali ke halaman sebelumnya | P0 |
| AUT-07 | Akses halaman khusus seller sebagai customer | Ditolak (403) atau tidak crash | P1 |

## 2. Registrasi Akun

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| REG-01 | Register sebagai Customer | Dialog sukses, diarahkan ke Login | P0 |
| REG-02 | Register sebagai Seller (akun baru) | Akun seller dibuat, bisa login | P1 |
| REG-03 | Pindah tab Customer ↔ Seller | Form berubah sesuai role | P1 |
| REG-04 | Email sudah terdaftar | Error ditampilkan, tidak silent | P0 |
| REG-05 | Data wajib kosong | Validasi inline per field | P0 |
| REG-06 | Format email salah | Validasi "email invalid" | P1 |
| REG-07 | Password < 6 karakter | Validasi ditolak | P1 |
| REG-08 | Konfirmasi password berbeda | Validasi ditolak | P1 |

## 3. Elevasi Akun (Customer → Seller)

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| ELE-01 | Buka kartu **ELEVASI AKUN** di profil customer | Form elevation tampil, tab Customer tetap tersedia | P0 |
| ELE-02 | Email customer otomatis terisi | Email terlihat dan tidak bisa diubah | P0 |
| ELE-03 | Masukkan password customer salah | Error, role tetap customer | P0 |
| ELE-04 | Masukkan password customer benar | Role berubah menjadi seller, token diperbarui, masuk ke SellerMainNav **tanpa logout** | P0 |
| ELE-05 | Ulangi elevasi pada akun yang sudah seller | Pesan "Akun ini sudah menjadi penjual" | P1 |
| ELE-06 | Dari tab Customer pada halaman elevation, register akun baru | Registrasi customer berhasil | P1 |
| ELE-07 | Restart aplikasi setelah elevasi | Masuk sebagai seller | P0 |

## 4. Profil & Foto Profil (Customer & Seller)

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| PRF-01 | Lihat profil | Nama, email, telepon, alamat sesuai data | P0 |
| PRF-02 | Update nama/email/telepon/alamat | Perubahan tersimpan, snackbar sukses | P0 |
| PRF-03 | Update password dengan current password benar | Password berubah | P0 |
| PRF-04 | Update password tanpa current password | Error: current password wajib diisi | P1 |
| PRF-05 | Simpan tanpa perubahan | Pesan "tidak ada perubahan" | P2 |
| PRF-06 | Ganti foto dari galeri | Foto profil berubah | P1 |
| PRF-07 | Ganti foto dari kamera, izin diberikan | Foto berhasil diunggah | P1 |
| PRF-08 | Izin kamera ditolak | Snackbar error, tidak crash | P1 |
| PRF-09 | Izin ditolak permanen | Snackbar dengan aksi **Pengaturan** yang membuka settings | P2 |

## 5. Katalog & Pencarian

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| CAT-01 | Buka katalog | Daftar produk tampil dengan gambar, harga, stok | P0 |
| CAT-02 | Cari berdasarkan nama produk | Hasil sesuai keyword | P0 |
| CAT-03 | Cari berdasarkan jenis kayu/kategori | Hasil sesuai keyword | P1 |
| CAT-04 | Cari keyword yang tidak ada | Empty state, bukan layar kosong/error | P1 |
| CAT-05 | Backend tidak bisa dijangkau | Error state + tombol **Coba Lagi** | P1 |
| CAT-06 | Tap produk | Halaman detail produk terbuka | P0 |

## 6. Detail Produk

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| DET-01 | Lihat detail | Spesifikasi, dimensi, harga, stok tampil | P0 |
| DET-02 | Tambah ke keranjang | Snackbar sukses, badge keranjang bertambah | P0 |
| DET-03 | Ubah jumlah lalu Beli Langsung | Jumlah terbawa ke checkout | P0 |
| DET-04 | Stok habis | Aksi beli/tambah tidak bisa dipakai | P1 |
| DET-05 | Produk tidak ditemukan | Empty/error state jelas | P2 |

## 7. Keranjang

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| CRT-01 | Tambah beberapa produk | Semua item tampil, subtotal benar | P0 |
| CRT-02 | Ubah quantity | Subtotal item dan total berubah sesuai harga × qty | P0 |
| CRT-03 | Quantity melebihi stok | Ditolak/dibatasi, tidak crash | P1 |
| CRT-04 | Hapus item | Dialog konfirmasi, item hilang setelah konfirmasi | P0 |
| CRT-05 | Pilih sebagian item | Hanya item terpilih dihitung | P0 |
| CRT-06 | Pilih semua / kosongkan pilihan | Subtotal mengikuti seleksi | P1 |
| CRT-07 | Checkout tanpa item dipilih | Snackbar "Pilih minimal satu item" | P0 |
| CRT-08 | Checkout dengan item dipilih | Halaman checkout terbuka, tidak red screen | P0 |

## 8. Checkout

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| CHK-01 | Buka checkout | Alamat otomatis terisi dari profil customer | P0 |
| CHK-02 | Biarkan alamat kosong lalu lanjut | Tetap bisa lanjut (alamat opsional) | P0 |
| CHK-03 | Ubah alamat manual | Alamat berubah dan ikut terkirim | P1 |
| CHK-04 | Lanjut Alamat → Pengiriman → Pembayaran → Ringkasan | Step indicator berpindah sesuai langkah | P0 |
| CHK-05 | Pilih metode pengiriman | Pilihan tersimpan, tampil di ringkasan | P1 |
| CHK-06 | Pilih metode pembayaran | Pilihan tersimpan, terbawa ke halaman pembayaran | P0 |
| CHK-07 | Lihat ringkasan | Subtotal hanya muncul **satu kali**, ongkir & total tampil | P0 |
| CHK-08 | Tekan **Konfirmasi & Bayar** | Loading muncul, order dibuat, halaman pembayaran terbuka | P0 |
| CHK-09 | Direct Buy | Order dibuat dengan item yang dipilih | P0 |
| CHK-10 | Checkout dari keranjang | Order dibuat, item terpilih terhapus dari keranjang | P0 |
| CHK-11 | Backend error saat konfirmasi | Snackbar error, tombol kembali aktif | P0 |
| CHK-12 | Layar kecil | Tombol konfirmasi tetap bisa di-scroll dan diketuk | P0 |

## 9. Halaman Pembayaran

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| PAY-01 | Muncul setelah checkout | Menggantikan halaman checkout, bukan menumpuk | P0 |
| PAY-02 | Total & nomor pesanan | Sesuai pesanan yang dibuat | P0 |
| PAY-03 | Status awal | "Menunggu pembayaran" | P0 |
| PAY-04 | Ganti metode pembayaran | Pilihan berubah, bisa dibayar | P1 |
| PAY-05 | Bayar sukses | Snackbar sukses, kembali ke navigasi utama | P0 |
| PAY-06 | Buka lagi pembayaran untuk order lunas | Tampil status **Pembayaran terverifikasi**, tombol bayar hilang | P1 |
| PAY-07 | Bayar order yang dibatalkan | Error ditampilkan, tidak crash | P1 |
| PAY-08 | Pull-to-refresh | Data pesanan diperbarui | P2 |

## 10. Pesanan Customer

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| ORD-01 | Order baru selesai dibuat, buka tab **Pesanan** | Order terbaru langsung tampil tanpa restart aplikasi | P0 |
| ORD-02 | Filter Semua/Berlangsung/Selesai/Dibatalkan | Daftar sesuai filter | P0 |
| ORD-03 | Buka detail pesanan | Resi, status, timeline 4 tahap, rincian produk tampil | P0 |
| ORD-04 | Batalkan pesanan sebelum diproses | Konfirmasi → status menjadi Dibatalkan | P0 |
| ORD-05 | Batalkan pesanan yang sudah dikirim | Aksi tidak tersedia / ditolak | P1 |
| ORD-06 | Upload bukti dari kamera, izin diberikan | Preview **9:16** muncul, bisa diganti | P0 |
| ORD-07 | Upload bukti dari galeri | Preview **9:16** muncul | P1 |
| ORD-08 | Izin kamera ditolak | Snackbar error, tidak crash | P1 |
| ORD-09 | Kirim bukti | Snackbar sukses, preview hilang, status berubah | P0 |
| ORD-10 | Tombol sync / pull-to-refresh | Status pengiriman terbaru tampil | P1 |

## 11. Onboarding Penjual

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| ONB-01 | Login seller pertama kali | Tutorial 4 langkah muncul otomatis | P1 |
| ONB-02 | Lanjutkan sampai langkah 4 | Tutorial selesai | P1 |
| ONB-03 | Skip tutorial | Tutorial tidak muncul lagi setelah restart | P2 |
| ONB-04 | Tekan ikon bantuan | Tutorial bisa dibuka ulang | P2 |

## 12. Dashboard Penjual (Overview)

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| DSH-01 | Buka Ringkasan | Total pendapatan, jumlah koleksi, total stok tampil | P0 |
| DSH-02 | Buku transaksi penjualan | Setiap pesanan tampil sekali; tidak ada subtotal ganda | P0 |
| DSH-03 | Belum ada transaksi | Empty state tampil | P1 |
| DSH-04 | Pull-to-refresh | Data berubah setelah transaksi baru | P1 |
| DSH-05 | Tap kartu koleksi/stok | Navigasi ke Inventaris | P2 |

## 13. Inventaris Penjual (CRUD)

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| INV-01 | Tambah produk lengkap + foto | Produk muncul di etalase | P0 |
| INV-02 | Tambah produk tanpa foto | Validasi ditolak | P0 |
| INV-03 | Field wajib kosong / harga invalid / stok negatif | Validasi inline | P0 |
| INV-04 | Edit harga & stok | Perubahan tersimpan, tampil di katalog customer | P0 |
| INV-05 | Edit foto produk | Foto berubah | P1 |
| INV-06 | Hapus produk | Dialog konfirmasi, produk hilang | P0 |
| INV-07 | Cari produk di inventaris | Hasil sesuai keyword | P1 |
| INV-08 | Izin kamera ditolak saat tambah foto | Snackbar error, tidak crash | P1 |

## 14. Logistik Penjual

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| LOG-01 | Lihat daftar pengiriman aktif | Pesanan In process tampil | P0 |
| LOG-02 | Update status menjadi **Out for delivery** | Status berubah, customer melihat timeline berubah | P0 |
| LOG-03 | Lihat foto bukti customer | Preview **9:16**, bisa di-zoom | P0 |
| LOG-04 | Verifikasi bukti lalu selesaikan pesanan | Status menjadi Arrived/selesai, transaksi tercatat di dashboard | P0 |
| LOG-05 | Belum ada pengiriman | Empty state tampil | P1 |
| LOG-06 | Pesanan selesai tampil di tab Selesai | Daftar sesuai filter | P1 |

## 15. Validasi Form (Ringkasan)

| Field | Aturan | Diharapkan |
|---|---|---|
| Nama | Wajib, tidak kosong | Error jika kosong |
| Email | Wajib, format `x@y.z` | Error jika invalid/duplikat |
| Password register | Minimal 6 karakter | Error jika < 6 |
| Konfirmasi password | Harus sama | Error jika beda |
| Telepon | Wajib | Error jika kosong |
| Alamat | Wajib di profil; **opsional di checkout** | Checkout tetap lanjut |
| Password saat ini (profil) | Wajib jika ganti password | Error jika kosong/salah |
| Harga produk | > 0 | Error jika 0/negatif |
| Stok produk | >= 0 | Error jika negatif |
| Jumlah order | 1–1000 | Ditolak di luar rentang |
| Foto produk | Wajib saat tambah | Error jika tidak ada |
| Bukti penerimaan | Wajib sebelum kirim | Tombol kirim tidak aktif jika belum ada |

## 16. Edge Case & Error Handling

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| ERR-01 | Koneksi putus saat login/checkout/payment/upload | Snackbar error, loading berhenti, tombol pulih | P0 |
| ERR-02 | Token expired/invalid | Kembali ke Login, tidak red screen | P0 |
| ERR-03 | Backend 500 | Pesan error user-friendly, bukan stack trace | P0 |
| ERR-04 | Stok tidak cukup saat checkout | Error jelas, order tidak dibuat | P0 |
| ERR-05 | Quantity sangat besar (> 1000) | Ditolak | P2 |
| ERR-06 | Izin penyimpanan ditolak saat upload | Error ditampilkan | P2 |
| ERR-07 | Gambar URL http pada perangkat | Ditampilkan sebagai https / error state, tidak crash | P2 |
| ERR-08 | Rotasi layar saat checkout/detail | State tidak hilang, layout tidak overflow | P2 |

## 17. Lokalisasi & Tampilan

| ID | Skenario | Expected Result | Prioritas |
|---|---|---|---|
| UI-01 | Ganti Bahasa Indonesia → English | Label di semua halaman utama berubah | P1 |
| UI-02 | Ganti kembali ke Indonesia | Label kembali Bahasa Indonesia | P1 |
| UI-03 | Tema gelap konsisten | Tidak ada area putih mencolok | P2 |
| UI-04 | Layar kecil (mis. 360x640) | Tidak ada overflow/red screen pada checkout & dialog bukti | P0 |
| UI-05 | Semua dialog | Bisa ditutup dengan tombol/back | P1 |

---

## Template Lapor Bug

```text
ID Checklist   : CHK-08
Tanggal        : 2026-xx-xx
Perangkat      : SM A225F / Android xx
Backend        : lokal 10.0.2.2:3000 / hosted
Langkah ulang  :
  1. ...
  2. ...
Hasil aktual   : ...
Hasil expected : ...
Bukti          : screenshot / logcat
Severity       : P0 / P1 / P2
```

## Catatan Eksekusi

- Uji dengan **dua akun berbeda** (customer & seller) untuk memastikan isolasi data.
- Uji alur lintas peran: customer checkout → bayar → seller verifikasi → customer melihat status selesai.
- Uji ulang setelah setiap perubahan backend (terutama endpoint `upgrade-seller`, `cart-list`, dan `sales`).
