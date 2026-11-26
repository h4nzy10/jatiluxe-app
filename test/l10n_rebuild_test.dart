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
}
