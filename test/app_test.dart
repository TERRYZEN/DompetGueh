import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dompetgueh_flutter/core/controller.dart';
import 'package:dompetgueh_flutter/core/models.dart';
import 'package:dompetgueh_flutter/main.dart';
import 'fixtures.dart';

Future<void> start(
  WidgetTester tester,
  AppController c, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await c.initialize();
  await tester.pumpWidget(DompetGuehApp(controller: c));
  await tester.pumpAndSettle();
}

Future<void> saveScreenshot(WidgetTester tester, String name) async {
  // Optional internal render review: FLUTTER_PREVIEW_DIR=/absolute/path.
  final directory = Platform.environment['FLUTTER_PREVIEW_DIR'];
  if (directory == null) return;
  final render = tester.binding.rootElement!.renderObject!;
  RenderRepaintBoundary? boundary;
  void visit(RenderObject object) {
    if (boundary != null) return;
    if (object is RenderRepaintBoundary) {
      boundary = object;
      return;
    }
    object.visitChildren(visit);
  }

  visit(render);
  await tester.runAsync(() async {
    final image = await boundary!.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$directory/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final dm = FontLoader('DMSans');
    for (var i = 0; i < 4; i++) {
      dm.addFont(rootBundle.load('assets/fonts/font-$i.ttf'));
    }
    final manrope = FontLoader('Manrope');
    for (var i = 4; i < 9; i++) {
      manrope.addFont(rootBundle.load('assets/fonts/font-$i.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([dm.load(), manrope.load(), icons.load()]);
  });

  test(
    'Rupiah groups digits, handles zero/negative, and formats entered nominal',
    () {
      expect(rupiah(125000), 'Rp125.000');
      expect(rupiah(0), 'Rp0');
      expect(rupiah(-125000), '-Rp125.000');
      expect(
        RupiahInputFormatter()
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(text: '125000'),
            )
            .text,
        '125.000',
      );
      expect(
        RupiahInputFormatter()
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(text: '000125000'),
            )
            .text,
        '125.000',
      );
    },
  );

  test('failed preference save leaves controller settings unchanged', () async {
    final api = FixtureApi()..failSave = true;
    final c = AppController(api);
    await c.initialize();
    await expectLater(c.toggleDark(), throwsStateError);
    expect(c.dark, false);
    await expectLater(c.toggleHidden(), throwsStateError);
    expect(c.hideBudget, false);
    c.dispose();
  });

  test(
    'rapid preference taps serialize and preserve both saved settings',
    () async {
      final api = FixtureApi();
      final c = AppController(api);
      await c.initialize();
      await Future.wait([c.toggleDark(), c.toggleHidden()]);
      expect(c.dark, true);
      expect(c.hideBudget, true);
      expect(api.dark, true);
      expect(api.hidden, true);
      await Future.wait([c.toggleDark(), c.toggleDark()]);
      expect(c.dark, true);
      expect(api.dark, true);
      c.dispose();
    },
  );

  testWidgets(
    'dashboard, responsive widths, theme, hidden budget, and profile',
    (tester) async {
      final api = FixtureApi();
      final c = AppController(api);
      await start(tester, c);
      expect(find.byKey(const Key('budget-value')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-value'))).data,
        'Rp6.000.000',
      );
      for (final width in [360.0, 390.0, 430.0, 800.0]) {
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('add-entry')), findsOneWidget);
      }
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      await saveScreenshot(tester, 'flutter-dashboard-light');
      await tester.tap(find.byKey(const Key('toggle-theme')));
      await tester.pumpAndSettle();
      expect(c.dark, true);
      expect(api.dark, true);
      await saveScreenshot(tester, 'flutter-dashboard-dark');
      await tester.tap(find.byKey(const Key('toggle-hidden')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('budget-value'))).data,
        'Rp••••••',
      );
      await tester.tap(find.byKey(const Key('edit-profile')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profile-name-input')),
        'Terry Flutter',
      );
      await tester.tap(find.byKey(const Key('save-profile')));
      await tester.pumpAndSettle();
      expect(c.data.name, 'Terry Flutter');
      expect(api.calls.last.path, '/api/profil');
      expect(api.calls.last.method, 'PUT');
    },
  );

  testWidgets(
    'income form groups nominal and sends an integer to the local API',
    (tester) async {
      final api = FixtureApi();
      final c = AppController(api);
      await start(tester, c);
      await tester.tap(find.byKey(const Key('add-entry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('entry-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambahkan Pemasukan').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('name-pemasukan')),
        'Bonus offline',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('amount-pemasukan')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('amount-pemasukan')),
        '125000',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('amount-pemasukan')),
            )
            .controller!
            .text,
        '125.000',
      );
      await tester.ensureVisible(find.byKey(const Key('save-entry')));
      await tester.tap(find.byKey(const Key('save-entry')));
      await tester.pumpAndSettle();
      final call = api.calls.last;
      expect(call.path, '/api/pemasukan');
      expect(call.method, 'POST');
      expect(call.body['jumlah'], 125000);
      expect(c.data.budget, 6125000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('history chart, filters, confirmation cancel, and delete', (
    tester,
  ) async {
    final api = FixtureApi();
    final c = AppController(api);
    await start(tester, c);
    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(find.text('Grafik Pemasukan & Pengeluaran'), findsOneWidget);
    await saveScreenshot(tester, 'flutter-history-light');
    await tester.ensureVisible(find.byKey(const Key('delete-2')));
    await tester.tap(find.byKey(const Key('delete-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(c.data.expenses.length, 1);
    await tester.tap(find.byKey(const Key('delete-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();
    expect(c.data.expenses, isEmpty);
    expect(api.calls.last.method, 'DELETE');
    await tester.ensureVisible(find.byKey(const Key('history-type')));
    await tester.tap(find.byKey(const Key('history-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengeluaran').last);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada transaksi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new PIN confirms, shows recovery once, and opens dashboard', (
    tester,
  ) async {
    final api = FixtureApi(unlocked: false, setup: true);
    final c = AppController(api);
    await start(tester, c, size: const Size(360, 740));
    expect(find.text('Buat PIN Keamanan'), findsOneWidget);
    await saveScreenshot(tester, 'flutter-pin-setup');
    await tester.enterText(find.byKey(const Key('pin-input')), '1234');
    await tester.enterText(find.byKey(const Key('confirm-pin')), '9999');
    await tester.ensureVisible(find.byKey(const Key('submit-pin')));
    await tester.tap(find.byKey(const Key('submit-pin')));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi PIN tidak sama.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('confirm-pin')), '1234');
    await tester.tap(find.byKey(const Key('submit-pin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recovery-code')), findsOneWidget);
    expect(c.unlocked, false);
    await tester.tap(find.byKey(const Key('finish-recovery')));
    await tester.pumpAndSettle();
    expect(c.unlocked, true);
    expect(find.byKey(const Key('budget-value')), findsOneWidget);
  });

  testWidgets(
    'wrong PIN, recovery, lock, and new PIN all follow their routes',
    (tester) async {
      final api = FixtureApi(unlocked: false);
      final c = AppController(api);
      await start(tester, c);
      await tester.enterText(find.byKey(const Key('pin-input')), '9999');
      await tester.tap(find.byKey(const Key('submit-pin')));
      await tester.pumpAndSettle();
      expect(find.text('PIN salah. Silakan coba lagi.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('forgot-pin')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('recovery-input')),
        recoveryCode,
      );
      await tester.enterText(find.byKey(const Key('pin-input')), '5678');
      await tester.enterText(find.byKey(const Key('confirm-pin')), '5678');
      await tester.ensureVisible(find.byKey(const Key('submit-pin')));
      await tester.tap(find.byKey(const Key('submit-pin')));
      await tester.pumpAndSettle();
      expect(api.calls.last.path, '/api/pin/reset');
      await tester.tap(find.byKey(const Key('finish-recovery')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lock-app')));
      await tester.pumpAndSettle();
      expect(c.unlocked, false);
      expect(c.data.expenses, isEmpty);
      await tester.enterText(find.byKey(const Key('pin-input')), '5678');
      await tester.tap(find.byKey(const Key('submit-pin')));
      await tester.pumpAndSettle();
      expect(c.unlocked, true);
      expect(tester.takeException(), isNull);
    },
  );
}
