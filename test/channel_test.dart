import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dompetgueh_flutter/core/controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('id.terry.dompetgueh/local');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'Android transport encodes request body and decodes native response',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'request');
        final args = call.arguments as Map;
        expect(args['path'], '/api/pemasukan');
        expect(args['method'], 'POST');
        expect(jsonDecode(args['body'] as String), {'jumlah': 125000});
        return jsonEncode({
          'ok': true,
          'result': {
            'pesan': 'Disimpan',
            'data': {'anggaran': 125000},
          },
        });
      });
      final result = await AndroidLocalApi().request(
        '/api/pemasukan',
        method: 'POST',
        body: {'jumlah': 125000},
      );
      expect(result['pesan'], 'Disimpan');
      expect(result['data']['anggaran'], 125000);
    },
  );

  test(
    'native validation errors become visible errors without changing data',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async =>
            jsonEncode({'ok': false, 'pesan': 'PIN salah. Silakan coba lagi.'}),
      );
      await expectLater(
        AndroidLocalApi().request(
          '/api/pin/unlock',
          method: 'POST',
          body: {'pin': '9999'},
        ),
        throwsA(
          isA<StateError>().having(
            (e) => errorText(e),
            'message',
            'PIN salah. Silakan coba lagi.',
          ),
        ),
      );
    },
  );

  test('theme and visibility preference channel contract', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'preferences')
        return {'dark': true, 'hideBudget': false};
      expect(call.method, 'savePreferences');
      expect(call.arguments, {'dark': false, 'hideBudget': true});
      return true;
    });
    final api = AndroidLocalApi();
    expect(await api.preferences(), {'dark': true, 'hideBudget': false});
    await api.savePreferences(dark: false, hideBudget: true);
  });
}
