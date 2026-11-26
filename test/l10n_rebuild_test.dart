import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jatiluxe_app/service/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppL10n.init();
  });

  testWidgets('TText updates when the language changes on a pushed route',
      (tester) async {
    await AppL10n.setLanguage('id');

    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: AppL10n.locale,
        builder: (context, locale, _) => MaterialApp(
          locale: locale,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          body: Center(child: TText('Welcome Back')),
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat Datang Kembali'), findsOneWidget);

    await AppL10n.setLanguage('en');
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('L10nBuilder updates strings outside Text widgets', (tester) async {
    await AppL10n.setLanguage('id');

    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: AppL10n.locale,
        builder: (context, locale, _) => MaterialApp(
          locale: locale,
          home: L10nBuilder(
            builder: (context) => Scaffold(
              body: Center(child: Text('Semua'.tr(context))),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Semua'), findsOneWidget);

    await AppL10n.setLanguage('en');
    await tester.pumpAndSettle();
    expect(find.text('All'), findsOneWidget);
  });

  test('inventory strings are translated to English', () {
    const en = Locale('en');
    expect(AppL10n.translate('Semua', en), 'All');
    expect(AppL10n.translate('Katalog & Inventaris Furnitur', en),
        'Furniture Catalog & Inventory');
    expect(AppL10n.translate('KATALOG & INVENTARIS', en),
        'CATALOG & INVENTORY');
    expect(AppL10n.translate('INVENTARIS KATALOG', en), 'CATALOG INVENTORY');
    expect(
        AppL10n.translate('Cari nama mebel, ukiran, atau kategori...', en),
        'Search furniture, carvings, or categories...');
    expect(AppL10n.translate('Nama Karya Mebel', en), 'Furniture Name');
    expect(AppL10n.translate('Jenis Kayu', en), 'Wood Type');
  });

  test('profile snackbar strings are translated to English', () {
    const en = Locale('en');
    expect(AppL10n.translate('Profil workshop berhasil disimpan', en),
        'Workshop profile saved successfully');
    expect(AppL10n.translate('Tidak ada perubahan untuk disimpan', en),
        'No changes to save');
    expect(AppL10n.translate('Foto profil workshop diperbarui', en),
        'Workshop profile photo updated');
    expect(
        AppL10n.translate('Gagal menyimpan profil: Network error', en),
        'Failed to save profile: Network error');
    expect(AppL10n.translate('Pengaturan', en), 'Settings');
  });

  test('customer catalog strings are translated to English', () {
    const en = Locale('en');
    expect(AppL10n.translate('KOLEKSI JATILUXE', en), 'JATILUXE COLLECTION');
    expect(AppL10n.translate('Katalog', en), 'Catalog');
    expect(AppL10n.translate('Katalog JatiLuxe', en), 'JatiLuxe Catalog');
    expect(AppL10n.translate('Koleksi Jati', en), 'Teak Collection');
    expect(AppL10n.translate('KARYA PILIHAN', en), 'SELECTED PIECE');
    expect(
        AppL10n.translate('Temukan karya kayu jati pilihan untuk rumah Anda', en),
        'Discover curated teak pieces for your home');
    expect(
        AppL10n.translate('Cari furnitur, jenis kayu, atau kategori...', en),
        'Search furniture, wood types, or categories...');
    expect(AppL10n.translate('Belum ada furnitur di katalog', en),
        'No furniture in the catalog yet');
    expect(AppL10n.translate('Oleh Jati Makmur', en),
        'By Jati Makmur');
  });

  test('product detail strings are translated to English', () {
    const en = Locale('en');
    expect(AppL10n.translate('Detail Produk', en), 'Product Details');
    expect(AppL10n.translate('SPESIFIKASI KARYA', en),
        'PIECE SPECIFICATIONS');
    expect(AppL10n.translate('DESKRIPSI & DIMENSI', en),
        'DESCRIPTION & DIMENSIONS');
    expect(AppL10n.translate('Pengrajin', en), 'Artisan');
    expect(AppL10n.translate('Jumlah', en), 'Quantity');
    expect(AppL10n.translate('Tambah ke Keranjang', en), 'Add to Cart');
    expect(AppL10n.translate('Beli Langsung', en), 'Buy Now');
    expect(AppL10n.translate('Produk ditambahkan ke keranjang', en),
        'Product added to cart');
    expect(
        AppL10n.translate('Gagal menambahkan ke keranjang: Server error', en),
        'Failed to add to cart: Server error');
    expect(AppL10n.translate('ANDA MUNGKIN SUKA', en), 'YOU MAY ALSO LIKE');
  });

  test('cart strings are translated to English', () {
    const en = Locale('en');
    expect(AppL10n.translate('Keranjang', en), 'Cart');
    expect(AppL10n.translate('Keranjang Saya', en), 'My Cart');
    expect(AppL10n.translate('Pilih Semua', en), 'Select All');
    expect(AppL10n.translate('Pilih item', en), 'Select item');
    expect(AppL10n.translate('Subtotal', en), 'Subtotal');
    expect(AppL10n.translate('Total', en), 'Total');
    expect(AppL10n.translate('Lanjut ke Checkout', en),
        'Continue to Checkout');
    expect(AppL10n.translate('Keranjang masih kosong', en),
        'Your cart is empty');
    expect(
        AppL10n.translate('Temukan karya kayu favorit Anda di katalog', en),
        'Find your favorite wood pieces in the catalog');
    expect(AppL10n.translate('Jelajahi Katalog', en), 'Explore Catalog');
    expect(AppL10n.translate('Gagal memuat keranjang', en),
        'Failed to load cart');
    expect(AppL10n.translate('Item dihapus dari keranjang', en),
        'Item removed from cart');
    expect(AppL10n.translate('Hapus item ini dari keranjang?', en),
        'Remove this item from the cart?');
    expect(AppL10n.translate('Ya, Hapus', en), 'Yes, Remove');
    expect(AppL10n.translate('Pilih minimal satu item', en),
        'Select at least one item');
    expect(AppL10n.translate('1 item dipilih', en), '1 item selected');
    expect(AppL10n.translate('3 item dipilih', en), '3 items selected');
    expect(
        AppL10n.translate('Gagal memperbarui keranjang: Network error', en),
        'Failed to update cart: Network error');
    expect(AppL10n.translate('Gagal menghapus item: Server error', en),
        'Failed to remove item: Server error');
  });
}
