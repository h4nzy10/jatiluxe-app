import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/theme.dart';

/// Lightweight localization layer.
///
/// UI literals are used as translation keys so existing widgets can be
/// converted without inventing a second set of identifiers. Indonesian is the
/// source language of most strings; a smaller set of screens were written in
/// English and are mapped back to Indonesian via [_indonesian].
class AppL10n {
  static const String _storageKey = 'app_language';
  static const Locale defaultLocale = Locale('id');

  static final ValueNotifier<Locale> locale = ValueNotifier(defaultLocale);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey);
    if (code == 'id' || code == 'en') {
      locale.value = Locale(code!);
    }
  }

  static Future<void> setLanguage(String code) async {
    if (code != 'id' && code != 'en') return;
    if (locale.value.languageCode == code) return;
    locale.value = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, code);
  }

  static String translate(String source, Locale locale) {
    if (locale.languageCode == 'id') {
      return _indonesian[source] ?? source;
    }

    final exact = _english[source];
    if (exact != null) return exact;

    // Interpolated strings cannot be matched exactly. Apply the longest
    // phrase replacements first so that specific sentences win over generic
    // single words.
    var result = source;
    for (final entry in _englishPhrases) {
      result = result.replaceAll(entry.$1, entry.$2);
    }
    return result;
  }

  /// English literals in the source code that need an Indonesian rendering.
  static const Map<String, String> _indonesian = {
    'Welcome Back': 'Selamat Datang Kembali',
    'Log in to explore the finest wood furniture':
        'Masuk untuk menjelajahi karya furnitur kayu terbaik',
    'Join to explore and order premium Jepara wood furniture.':
        'Gabung untuk menjelajah dan memesan furnitur kayu Jepara premium.',
    'Open a digital showcase and market quality wood furniture directly to collectors.': 'Buka etalase digital dan pasarkan furnitur kayu berkualitas langsung ke kolektor.',
    'Email': 'Email',
    'Password': 'Kata Sandi',
    'Login': 'Masuk',
    'Login Now': 'Masuk Sekarang',
    "Don't have account? ": 'Belum punya akun? ',
    'Already have an account? ': 'Sudah punya akun? ',
    'Register Now': 'Daftar Sekarang',
    'Register As Seller': 'Daftar sebagai Penjual',
    'Register As Customer': 'Daftar sebagai Pelanggan',
    'Register Account': 'Daftar Akun',
    'Register Successfuly': 'Pendaftaran Berhasil',
    'Customer': 'Pelanggan',
    'By': 'Oleh',
    'Delete Karya Jati': 'Hapus Karya Jati',
    'Profile picture successfully updated': 'Foto profil berhasil diperbarui',
    'Wooden Furniture': 'Furnitur Kayu',
    // Checkout
    'Pembayaran': 'Pembayaran',
    'Lanjut': 'Lanjut',
    'Alamat Pengiriman': 'Alamat Pengiriman',
    'Metode Pengiriman': 'Metode Pengiriman',
    'Ekspres': 'Ekspres',
    'Standar': 'Standar',
    'Next Day': 'Next Day',
    'Metode Pembayaran': 'Metode Pembayaran',
    'Transfer Bank': 'Transfer Bank',
    'E-Wallet': 'E-Wallet',
    'Cash on Delivery': 'Cash on Delivery',
    'Ringkasan & Konfirmasi': 'Ringkasan & Konfirmasi',
    'Tidak ada produk dipilih': 'Tidak ada produk dipilih',
    'Kembali ke keranjang': 'Kembali ke keranjang',
    'Pesanan berhasil dibuat': 'Pesanan berhasil dibuat',
    'Gagal membuat pesanan': 'Gagal membuat pesanan',
    'Metode pembayaran wajib dipilih': 'Metode pembayaran wajib dipilih',
    'Konfirmasi & Bayar': 'Konfirmasi & Bayar',
    'Subtotal': 'Subtotal',
    'Pengiriman': 'Pengiriman',
    'Total': 'Total',
  };

  /// Indonesian literals in the source code translated to English.
  static const Map<String, String> _english = {
    // Common
    'Batal': 'Cancel',
    'Semua': 'All',
    'Hapus': 'Delete',
    'Tutup': 'Close',
    'Keluar': 'Logout',
    'Keluar dari Toko': 'Exit Store',
    'Coba Lagi': 'Try Again',
    'Muat Ulang': 'Reload',
    'Muat ulang': 'Reload',
    'Sinkronisasi Data': 'Sync Data',
    'Tandai "Dikirim" — Barang Keluar Gudang':
        'Mark "Out for delivery" — Goods Left Warehouse',
    'Panduan Toko': 'Store Guide',
    'Bahasa / Language': 'Language / Bahasa',
    'Periksa koneksi server Anda': 'Check your server connection',
    'J A T I L U X E': 'J A T I L U X E',
    'JATILUXE': 'JATILUXE',
    '✦': '✦',

    // Customer catalog
    'KOLEKSI JATILUXE': 'JATILUXE COLLECTION',
    'Temukan karya kayu pilihan untuk rumah Anda':
        'Discover curated wood pieces for your home',
    'Cari furnitur, jenis kayu, atau kategori...':
        'Search furniture, wood types, or categories...',
    'Gagal memuat katalog': 'Failed to load catalog',
    'Belum ada furnitur di katalog': 'No furniture in the catalog yet',
    'Coba kata kunci atau kategori lain': 'Try another keyword or category',
    'Detail Produk': 'Product Details',
    'SPESIFIKASI KARYA': 'PIECE SPECIFICATIONS',
    'DESKRIPSI & DIMENSI': 'DESCRIPTION & DIMENSIONS',
    'Pengrajin': 'Artisan',
    'Jumlah': 'Quantity',
    'Tambah ke Keranjang': 'Add to Cart',
    'Beli Langsung': 'Buy Now',
    'Produk ditambahkan ke keranjang': 'Product added to cart',
    'Gagal memuat detail produk': 'Failed to load product details',
    'Produk tidak ditemukan': 'Product not found',
    'ANDA MUNGKIN SUKA': 'YOU MAY ALSO LIKE',
    'Oleh': 'By',

    // Seller navigation
    'RUANG PENJUAL': 'MERCHANT SUITE',
    'INVENTARIS KATALOG': 'CATALOG INVENTORY',
    'LOGISTIK & PENGIRIMAN': 'LOGISTICS & DELIVERY',
    'PROFIL TOKO': 'STORE PROFILE',
    'Ringkasan': 'Overview',
    'Inventaris': 'Inventory',
    'Logistik': 'Logistics',
    'Profil Toko': 'Store Profile',
    'Apakah Anda yakin ingin mengakhiri sesi merchant ini?':
        'Are you sure you want to end this merchant session?',
    'KATALOG & INVENTARIS': 'CATALOG & INVENTORY',
    'MANAJEMEN ETALASE & OPERASIONAL': 'CATALOG & OPERATIONS MANAGEMENT',

    // Dashboard
    'TOTAL PENDAPATAN TERVERIFIKASI': 'TOTAL VERIFIED REVENUE',
    'KOLEKSI AKTIF': 'ACTIVE COLLECTION',
    'Katalog & Inventaris Furnitur': 'Furniture Catalog & Inventory',
    'Perbarui harga, stok kayu, dan foto spesifikasi':
        'Update prices, wood stock, and specification photos',
    'Otorisasi Logistik & Pengiriman': 'Logistics & Shipping Authorization',
    'Perbarui keberangkatan armada & verifikasi foto bukti terima':
        'Update fleet departures & verify delivery receipt photos',
    'TOTAL STOK KAYU': 'TOTAL WOOD STOCK',
    'TOTAL STOK': 'TOTAL STOCK',
    'NILAI': 'VALUE',
    'PRODUK': 'PRODUCTS',
    'Terdaftar di etalase': 'Listed in the catalog',
    'BUKU TRANSAKSI PENJUALAN': 'SALES TRANSACTION LEDGER',
    'Belum ada riwayat transaksi penjualan terbayar':
        'No paid sales transactions yet',
    'Transaksi selesai — Barang diterima kolektor':
        'Transaction complete — Item received by collector',

    // Inventory
    'Cari nama mebel, ukiran, atau kategori...':
        'Search furniture, carvings, or categories...',
    'Contoh: Meja Makan Kayu Solid Trembesi':
        'Example: Solid Trembesi Wood Dining Table',
    'Sebutkan dimensi (P x L x T), teknik finishing kayu (natural oil, walnut), dan keunggulan serat.': 'Mention dimensions (W x D x H), wood finishing (natural oil, walnut), and grain highlights.',
    'Tambah Karya': 'Add Piece',
    'Hapus Karya': 'Delete Piece',
    'Tambah Karya Pertama': 'Add First Piece',
    'Tambah Karya Kayu Baru': 'Add New Wood Piece',
    'Perbarui Karya Kayu': 'Update Wood Piece',
    'Daftarkan Karya ke Etalase': 'List Piece in Catalog',
    'Belum Ada Koleksi Kayu': 'No Wood Collection Yet',
    'Mulai daftarkan karya furnitur kayu Anda ke etalase untuk dilihat para kolektor.': 'Start listing your wood furniture pieces in the catalog for collectors to see.',
    'Standar JatiLuxe: Setiap produk kayu yang didaftarkan wajib mencantumkan jenis kayu serta difoto dengan pencahayaan alami tanpa manipulasi warna serat.': 'JatiLuxe standard: every registered wood product must state the wood type and be photographed in natural light without altering the wood grain color.',
    'Nama Karya Mebel': 'Furniture Name',
    'Kategori': 'Category',
    'Jenis Kayu': 'Wood Type',
    'Harga (Rupiah)': 'Price (IDR)',
    'Stok Unit': 'Stock Units',
    'Deskripsi Spesifikasi & Dimensi': 'Specifications & Dimensions',
    'Nama wajib diisi': 'Name is required',
    'Harga wajib diisi': 'Price is required',
    'Harga tidak valid': 'Invalid price',
    'Stok wajib': 'Stock is required',
    'Stok >= 0': 'Stock >= 0',
    'Deskripsi wajib diisi': 'Description is required',
    'Foto karya mebel wajib diunggah': 'Product photo is required',
    'Unggah Foto Mebel': 'Upload Furniture Photo',
    'Ambil Foto Kamera': 'Take Camera Photo',
    'Ambil dari Kamera': 'Take from Camera',
    'Pilih dari Galeri': 'Choose from Gallery',
    'Stok Habis': 'Out of Stock',
    'Foto pencahayaan alami beresolusi tinggi':
        'High-resolution photo in natural light',
    'Karya kayu berhasil diperbarui': 'Wood piece updated successfully',
    'Karya mebel berhasil didaftarkan ke etalase':
        'Furniture piece added to the catalog successfully',
    'Produk berhasil dihapus dari etalase':
        'Product removed from the catalog successfully',
    'Apakah Anda yakin ingin menghapus': 'Are you sure you want to delete',
    'Gagal Memuat Inventaris': 'Failed to Load Inventory',
    'Gagal Memuat Data': 'Failed to Load Data',

    // Delivery
    'Aktif': 'Active',
    'Selesai': 'Completed',
    'MANAJEMEN ARMADA': 'FLEET MANAGEMENT',
    'PERBARUI STATUS ARMADA': 'UPDATE FLEET STATUS',
    'Diproses': 'In process',
    'Dikirim': 'Out for delivery',
    'Tiba': 'Arrived',
    'Perbarui Status': 'Update Status',
    'Lihat Foto': 'View Photo',
    'Selesaikan': 'Complete',
    'Selesaikan Pesanan': 'Complete Order',
    'Tidak ada pengiriman aktif': 'No active deliveries',
    'Belum ada pesanan selesai': 'No completed orders yet',
    'Pesanan yang sedang dalam proses pengiriman akan muncul di sini':
        'Orders currently being shipped will appear here',
    'Transaksi yang telah selesai dan diterima kolektor akan tercatat di sini':
        'Completed transactions received by collectors will be recorded here',
    'Menunggu konfirmasi penerimaan dari pelanggan':
        'Awaiting receipt confirmation from the customer',
    'Siap diproses & dikirim': 'Ready to process & ship',
    'Bukti penerimaan dari pelanggan': 'Receipt proof from the customer',
    'BUKTI PENERIMAAN BARANG': 'PROOF OF GOODS RECEIPT',
    'Gagal memuat data logistik': 'Failed to load logistics data',
    'Gagal memuat gambar bukti': 'Failed to load proof image',
    'No. Lacak': 'Tracking No.',

    // Profile
    'IDENTITAS PENGRAJIN': 'ARTISAN IDENTITY',
    'KEAMANAN AKUN': 'ACCOUNT SECURITY',
    'MITRA PENJUAL TERVERIFIKASI': 'VERIFIED SELLER PARTNER',
    'SIMPAN PERUBAHAN': 'SAVE CHANGES',
    'Panduan Orientasi Toko': 'Store Onboarding Guide',
    'Ulangi tutorial 4 langkah untuk mengelola etalase':
        'Replay the 4-step guide to manage your catalog',
    'Nama workshop / pengrajin': 'Workshop / artisan name',
    'Nomor telepon': 'Phone number',
    'Alamat galeri': 'Gallery address',
    'Lokasi galeri belum diatur': 'Gallery location not set yet',
    'FOTO PROFIL WORKSHOP': 'WORKSHOP PROFILE PHOTO',
    'Foto Profil Workshop / Galeri': 'Workshop / Gallery Profile Photo',
    'Kata sandi saat ini': 'Current password',
    'Kata sandi baru': 'New password',
    'Wajib diisi jika ingin mengubah kata sandi':
        'Required if you want to change your password',
    'Minimal 6 karakter, kosongkan jika tidak diubah':
        'At least 6 characters, leave blank to keep unchanged',
    'Tampilkan kata sandi': 'Show password',
    'Sembunyikan kata sandi': 'Hide password',
    'Nama workshop': 'Workshop name',
    'Format email tidak valid': 'Invalid email format',
    'Kata sandi saat ini wajib diisi untuk mengubah kata sandi.':
        'Current password is required to change your password.',
    'Perubahan identitas dan foto workshop akan langsung tersinkron dengan katalog dan pesanan Anda.': 'Identity and workshop photo changes will sync instantly with your catalog and orders.',
    'Gagal memuat profil workshop': 'Failed to load workshop profile',
    'Data profil workshop tidak ditemukan.':
        'Workshop profile data was not found.',
    'Kata sandi saat ini wajib diisi': 'Current password is required',
    'Kata sandi baru minimal 6 karakter':
        'New password must be at least 6 characters',
    'Profil workshop berhasil disimpan': 'Workshop profile saved successfully',
    'Tidak ada perubahan untuk disimpan': 'No changes to save',
    'Foto profil workshop diperbarui': 'Workshop profile photo updated',
    'Izin kamera ditolak. Aktifkan dari pengaturan perangkat.':
        'Camera permission denied. Enable it in device settings.',
    'Izin kamera diperlukan untuk mengambil foto':
        'Camera permission is required to take a photo',
    'Pengaturan': 'Settings',
    'Gagal mengunggah foto:': 'Failed to upload photo:',
    'Gagal menyimpan:': 'Failed to save:',

    // Onboarding
    'LEWATI': 'SKIP',
    'Sebelumnya': 'Previous',
    'Lanjut': 'Next',
    'Mulai Berjualan': 'Start Selling',
    'LANGKAH 1 DARI 4': 'STEP 1 OF 4',
    'LANGKAH 2 DARI 4': 'STEP 2 OF 4',
    'LANGKAH 3 DARI 4': 'STEP 3 OF 4',
    'LANGKAH 4 DARI 4': 'STEP 4 OF 4',
    'Kenali Ruang Kendali Toko': 'Get to Know Your Store Dashboard',
    'Ringkasan menampilkan pendapatan, jumlah pesanan, dan kondisi etalase Anda dalam satu tampilan.': 'The overview shows your revenue, order count, and catalog status in one view.',
    'Pantau total pendapatan terverifikasi': 'Monitor total verified revenue',
    'Cek koleksi aktif dan total stok kayu':
        'Check active collections and wood stock',
    'Gunakan ringkasan untuk melihat pesanan terbaru':
        'Use the overview to see recent orders',
    'Bangun Etalase Berkualitas': 'Build a Quality Catalog',
    'Tambah karya kayu pilihan lengkap dengan foto, kategori, spesifikasi, harga, dan stok.': 'Add quality wood pieces with photos, categories, specifications, prices, and stock.',
    'Gunakan foto dengan pencahayaan alami': 'Use photos with natural lighting',
    'Isi dimensi dan teknik finishing di deskripsi':
        'Include dimensions and finishing technique in the description',
    'Perbarui harga dan stok secara berkala':
        'Update prices and stock regularly',
    'Kelola Pengiriman sampai Selesai': 'Manage Delivery Through Completion',
    'Temukan pesanan pada tab Logistik, lalu awalui status pengiriman dan verifikasi bukti penerimaan pelanggan.': 'Find orders in the Logistics tab, track delivery status, and verify customer receipt proof.',
    'Tandai pesanan menjadi "Dikirim" saat barang keluar':
        'Mark an order as "Out for delivery" when the item ships',
    'Lihat foto bukti yang diunggah pelanggan':
        'View proof photos uploaded by the customer',
    'Selesaikan transaksi setelah bukti terverifikasi':
        'Complete the transaction once proof is verified',
    'Rapikan Identitas Workshop': 'Polish Your Workshop Identity',
    'Lengkapi profil dan foto workshop agar pembeli mengenal pengrajin di balik setiap karya.': 'Complete your profile and workshop photo so buyers know the artisan behind each piece.',
    'Isi nama, email, telepon, dan alamat galeri':
        'Fill in your name, email, phone, and gallery address',
    'Ganti kata sandi hanya dengan kata sandi saat ini':
        'Change your password only with your current password',
    'Buka panduan ini kapan saja dari ikon bantuan':
        'Open this guide anytime from the help icon',

    // Customer
    'Katalog': 'Catalog',
    'Katalog JatiLuxe': 'JatiLuxe Catalog',
    'Koleksi Kayu': 'Wood Collection',
    'KARYA PILIHAN': 'SELECTED PIECE',
    'Keranjang': 'Cart',
    'Keranjang Saya': 'My Cart',
    'Pilih Semua': 'Select All',
    'Pilih item': 'Select item',
    'Subtotal': 'Subtotal',
    'Total': 'Total',
    'Lanjut ke Checkout': 'Continue to Checkout',
    'Keranjang masih kosong': 'Your cart is empty',
    'Temukan karya kayu favorit Anda di katalog':
        'Find your favorite wood pieces in the catalog',
    'Jelajahi Katalog': 'Explore Catalog',
    'Gagal memuat keranjang': 'Failed to load cart',
    'Item dihapus dari keranjang': 'Item removed from cart',
    'Hapus item ini dari keranjang?': 'Remove this item from the cart?',
    'Ya, Hapus': 'Yes, Remove',
    'Pilih minimal satu item': 'Select at least one item',
    '1 item dipilih': '1 item selected',

    // Payment
    'PEMBAYARAN': 'PAYMENT',
    'SELESAIKAN PEMBAYARAN': 'COMPLETE PAYMENT',
    'Total Pembayaran': 'Total Payment',
    'TOTAL PEMBAYARAN': 'TOTAL PAYMENT',
    'Metode Pembayaran': 'Payment Method',
    'METODE PEMBAYARAN': 'PAYMENT METHOD',
    'Pilih metode pembayaran untuk memproses pesanan dan menerbitkan resi pengiriman.': 'Choose a payment method to process the order and issue the tracking number.',
    'Bayar Sekarang': 'Pay Now',
    'Menunggu pembayaran': 'Awaiting payment',
    'Lunas': 'Paid',
    'Pembayaran berhasil dikonfirmasi': 'Payment confirmed successfully',
    'Pembayaran terverifikasi': 'Payment verified',
    'Pesanan Anda sedang disiapkan pengrajin.': 'Your order is being prepared by the artisan.',
    'Lihat Pesanan': 'View Order',
    'Gagal memuat detail pesanan': 'Failed to load order details',
    'Data pesanan tidak ditemukan': 'Order data was not found',

    // Customer profile
    'PROFIL SAYA': 'MY PROFILE',
    'Profil': 'Profile',
    'IDENTITAS PELANGGAN': 'CUSTOMER IDENTITY',
    'Nama lengkap': 'Full name',
    'Alamat': 'Address',
    'FOTO PROFIL': 'PROFILE PHOTO',
    'Foto profil berhasil diperbarui': 'Profile photo updated successfully',
    'Profil berhasil disimpan': 'Profile saved successfully',
    'Gagal memuat profil': 'Failed to load profile',
    'Data profil tidak ditemukan.': 'Profile data was not found.',
    'Lokasi belum diatur': 'Location not set yet',
    'PELANGGAN JATILUXE': 'JATILUXE CUSTOMER',
    'Perubahan profil Anda akan tersinkron dengan pesanan.':
        'Your profile changes will sync with your orders.',
    'ELEVASI AKUN': 'ACCOUNT UPGRADE',
    'Daftar sebagai Penjual': 'Register As Seller',
    'Daftar Sekarang': 'Register Now',
    'Buka etalase digital dan pasarkan furnitur kayu berkualitas langsung ke kolektor.': 'Open a digital showcase and market quality wood furniture directly to collectors.',
    'Konfirmasi Keluar': 'Logout Confirmation',
    'Apakah Anda yakin ingin keluar dari akun ini?':
        'Are you sure you want to log out of this account?',
  };

  /// Ordered phrase replacements for interpolated strings. Longer, more
  /// specific phrases are listed first so they are applied before fragments.
  static const List<(String, String)> _englishPhrases = [
    ('Nama lengkap wajib diisi', 'Full name is required'),
    ('Apakah Anda yakin ingin menghapus ', 'Are you sure you want to delete '),
    (' dari katalog inventaris toko?', ' from the store inventory catalog?'),
    ('Pesanan no. ', 'Order no. '),
    (
      ' telah diterima dan diverifikasi. Konfirmasi untuk menyelesaikan transaksi?',
      ' has been received and verified. Confirm to complete the transaction?',
    ),
    (
      'Terlalu banyak percobaan gagal. Login kembali dalam ',
      'Too many failed attempts. Try again in ',
    ),
    (
      'Login ditunda karena terlalu banyak percobaan gagal. Coba lagi dalam ',
      'Login delayed due to too many failed attempts. Try again in ',
    ),
    (
      'Terlalu banyak kata sandi salah. Login ditunda selama ',
      'Too many incorrect passwords. Login delayed for ',
    ),
    ('Email atau kata sandi salah. ', 'Incorrect email or password. '),
    ('Email atau kata sandi salah.', 'Incorrect email or password.'),
    (' percobaan tersisa.', ' attempts remaining.'),
    ('Nama workshop wajib diisi', 'Workshop name is required'),
    ('Nomor telepon wajib diisi', 'Phone number is required'),
    ('Alamat wajib diisi', 'Address is required'),
    ('Email wajib diisi', 'Email is required'),
    ('Percobaan gagal: ', 'Failed attempts: '),
    ('Gagal menghapus: ', 'Failed to delete: '),
    ('Gagal mengunggah foto: ', 'Failed to upload photo: '),
    ('Gagal menyimpan profil: ', 'Failed to save profile: '),
    ('Gagal menyimpan: ', 'Failed to save: '),
    ('Stok: ', 'Stock: '),
    ('Terjual oleh ', 'Sold by '),
    ('Oleh ', 'By '),
    ('Gagal menambahkan ke keranjang: ', 'Failed to add to cart: '),
    ('Gagal memperbarui keranjang: ', 'Failed to update cart: '),
    ('Gagal menghapus item: ', 'Failed to remove item: '),
    (' item dipilih', ' items selected'),
    ('Penjual: ', 'Seller: '),
    ('Tunggu ', 'Wait '),
    ('No. Lacak', 'Tracking No.'),
    ('Pesanan #', 'Order #'),
    (
      ' pesanan telah selesai dan diterima kolektor',
      ' orders completed and received by collectors',
    ),
    (' pengiriman aktif', ' active deliveries'),
    (' Desain Terdaftar', ' Designs Listed'),
    (' Desain', ' Designs'),
    (' Transaksi', ' Transactions'),
    (' detik', ' seconds'),
    (' Unit', ' Units'),
    ('Selesai', 'Completed'),
    ('Diproses', 'In process'),
    ('Dikirim', 'Out for delivery'),
  ];
}

extension LocalizedText on String {
  /// Use for dynamic strings that cannot be a [TText].
  String tr(BuildContext context) =>
      AppL10n.translate(this, AppL10n.locale.value);
}

/// Rebuilds its child whenever the app language changes.
///
/// Use this around pages/sheets that contain translated values which cannot
/// be a [TText] (for example `InputDecoration.hintText` or tooltips).
class L10nBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;

  const L10nBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppL10n.locale,
      builder: (context, _, _) => builder(context),
    );
  }
}

/// A [Text] replacement that translates its source at build time.
class TText extends StatelessWidget {
  final String source;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool softWrap;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticsLabel;

  const TText(
    this.source, {
    super.key,
    this.style,
    this.textAlign,
    this.softWrap = true,
    this.maxLines,
    this.overflow,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Listen directly instead of relying on an ancestor to rebuild: the
    // Navigator caches route widgets, so a MaterialApp-level rebuild alone
    // does not guarantee that every visible Text is rebuilt.
    return ValueListenableBuilder<Locale>(
      valueListenable: AppL10n.locale,
      builder: (context, locale, _) => Text(
        AppL10n.translate(source, locale),
        style: style,
        textAlign: textAlign,
        softWrap: softWrap,
        maxLines: maxLines,
        overflow: overflow,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}

/// Compact language switcher for app bars and login screens.
class LanguageSwitcher extends StatelessWidget {
  final Color iconColor;

  const LanguageSwitcher({super.key, this.iconColor = AppColors.ashGrey});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.language, color: iconColor, size: 20),
      tooltip: 'Bahasa / Language'.tr(context),
      onSelected: AppL10n.setLanguage,
      itemBuilder: (_) => const [
        PopupMenuItem<String>(value: 'id', child: Text('Bahasa Indonesia')),
        PopupMenuItem<String>(value: 'en', child: Text('English')),
      ],
    );
  }
}
