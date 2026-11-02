import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dompetgueh_flutter/core/controller.dart';
import 'package:dompetgueh_flutter/core/models.dart';
import 'package:dompetgueh_flutter/main.dart';
import 'fixtures.dart';
import 'package:dompetgueh_flutter/ui/visuals.dart';
import 'package:dompetgueh_flutter/ui/glass_select.dart';

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
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('test-root'),
      child: DompetGuehApp(controller: c),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> saveScreenshot(WidgetTester tester, String name) async {
  // Optional internal render review: FLUTTER_PREVIEW_DIR=/absolute/path.
  final directory = Platform.environment['FLUTTER_PREVIEW_DIR'];
  if (directory == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('test-root')),
  );
  final oldShadowMode = debugDisableShadows;
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  try {
    debugDisableShadows = false;
    repaint(boundary);
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '$directory/$name.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = oldShadowMode;
    repaint(boundary);
    await tester.pump();
  }
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
      expect(rupiah(125000), 'Rp 125.000');
      expect(rupiah(0), 'Rp 0');
      expect(rupiah(-125000), '-Rp 125.000');
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
    'canceled transaction drafts survive reopening without changing financial data',
    (tester) async {
      final api = FixtureApi();
      final c = AppController(api);
      await start(tester, c);
      await tester.tap(find.byKey(const Key('add-entry')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('name-pengeluaran')),
        'Belanja draft',
      );
      await tester.enterText(
        find.byKey(const ValueKey('amount-pengeluaran')),
        '120000',
      );
      await tester.ensureVisible(find.byTooltip('Tutup'));
      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-entry')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('name-pengeluaran')),
            )
            .controller!
            .text,
        'Belanja draft',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('amount-pengeluaran')),
            )
            .controller!
            .text,
        '120.000',
      );
      expect(c.data.budget, 6000000);
      expect(api.calls.where((e) => e.method == 'POST'), isEmpty);
    },
  );

  testWidgets(
    'swipe both ways, vertical scrolling, and interactive controls preserve navigation',
    (tester) async {
      final api = FixtureApi();
      final c = AppController(api);
      await start(tester, c);
      await tester.dragFrom(const Offset(195, 410), const Offset(-150, 0));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('page-title'))).data,
        'Histori Keuangan',
      );
      await tester.dragFrom(const Offset(195, 410), const Offset(150, 0));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('page-title'))).data,
        'Dashboard',
      );
      await tester.drag(
        find.byKey(const Key('edit-budget')),
        const Offset(-130, 0),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('page-title'))).data,
        'Dashboard',
      );
      final scroller = tester
          .widget<SingleChildScrollView>(find.byKey(const Key('main-scroll')))
          .controller!;
      await tester.dragFrom(const Offset(195, 580), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(scroller.offset, greaterThan(0));
      expect(
        tester.widget<Text>(find.byKey(const Key('page-title'))).data,
        'Dashboard',
      );
    },
  );

  testWidgets(
    'progress animates, clamps overspending, and hides its accessible value',
    (tester) async {
      final api = FixtureApi();
      api.data = {
        ...fixtureData(),
        'anggaran': 100000,
        'pengeluaran': [
          {
            'id': 2,
            'nama': 'Belanja',
            'tanggal': '${DateTime.now().year}-10-01',
            'kategori': 'Kebutuhan',
            'jumlah': 40000,
          },
        ],
      };
      final c = AppController(api);
      await start(tester, c);
      expect(find.text('40% anggaran terpakai'), findsOneWidget);
      expect(
        tester
            .widget<FractionallySizedBox>(
              find.byKey(const Key('progress-fill')),
            )
            .widthFactor,
        closeTo(.4, .0001),
      );
      api.data = {...api.data, 'anggaran': 10000};
      await c.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 175));
      final middle = tester
          .widget<FractionallySizedBox>(find.byKey(const Key('progress-fill')))
          .widthFactor!;
      expect(middle, greaterThan(.4));
      expect(middle, lessThan(1));
      await tester.pumpAndSettle();
      expect(find.text('100% anggaran terpakai'), findsOneWidget);
      expect(
        tester
            .widget<FractionallySizedBox>(
              find.byKey(const Key('progress-fill')),
            )
            .widthFactor,
        1,
      );
      expect(
        tester
            .widget<BudgetProgress>(find.byKey(const Key('budget-progress')))
            .overBudget,
        true,
      );
      await tester.tap(find.byKey(const Key('toggle-hidden')));
      await tester.pumpAndSettle();
      final semantics = find.descendant(
        of: find.byKey(const Key('budget-progress')),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Anggaran terpakai',
        ),
      );
      expect(
        tester.widget<Semantics>(semantics).properties.value,
        'Anggaran disembunyikan',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('remaining-value'))).data,
        'Rp••••••',
      );
    },
  );

  testWidgets(
    'glass menu supports keyboard selection and escape without closing the form',
    (tester) async {
      final c = AppController(FixtureApi());
      await start(tester, c);
      await tester.tap(find.byKey(const Key('add-entry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('entry-type')));
      await tester.pumpAndSettle();
      expect(find.text('Catat uang yang keluar'), findsOneWidget);
      await saveScreenshot(tester, 'flutter-dropdown-210');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('name-pemasukan')), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('category-pemasukan')),
      );
      await tester.tap(find.byKey(const ValueKey('category-pemasukan')));
      await tester.pumpAndSettle();
      expect(find.text('Freelance'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Freelance'), findsNothing);
      expect(find.byKey(const Key('save-entry')), findsOneWidget);
      GlassSelect.closeAll();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact and landscape layouts retain dock and filters without overflow',
    (tester) async {
      final c = AppController(FixtureApi());
      await start(tester, c, size: const Size(320, 740));
      for (final size in [
        const Size(320, 740),
        const Size(430, 932),
        const Size(844, 390),
        const Size(800, 1024),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('nav-history')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('history-type')), findsOneWidget);
        await tester.tap(find.byKey(const Key('nav-dashboard')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
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
        'Rp 6.000.000',
      );
      for (final width in [360.0, 390.0, 430.0, 800.0]) {
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('add-entry')), findsOneWidget);
      }
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      final preview = Platform.environment['FLUTTER_PREVIEW_DIR'];
      if (preview != null) {
        final entries = <String, dynamic>{};
        for (final key in [
          'app-header',
          'finance-overview',
          'budget-heading',
          'budget-value',
          'remaining-card',
          'income-card',
          'expense-card',
          'category-panel',
          'bottom-dock',
        ]) {
          final r = tester.getRect(find.byKey(Key(key)));
          entries[key] = {
            'x': r.left,
            'y': r.top,
            'width': r.width,
            'height': r.height,
          };
        }
        await tester.runAsync(() async {
          File(
            '$preview/native-metrics.json',
          ).writeAsStringSync(jsonEncode(entries));
        });
      }
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
