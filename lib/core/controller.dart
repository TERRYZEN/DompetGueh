import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'models.dart';

abstract class LocalApi {
  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic> body = const {},
  });
  Future<Map<String, dynamic>> preferences();
  Future<void> savePreferences({required bool dark, required bool hideBudget});
}

class AndroidLocalApi implements LocalApi {
  static const _channel = MethodChannel('id.terry.dompetgueh/local');
  @override
  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic> body = const {},
  }) async {
    final raw = await _channel.invokeMethod<String>('request', {
      'path': path,
      'method': method,
      'body': jsonEncode(body),
    });
    if (raw == null) throw StateError('Penyimpanan Android tidak merespons.');
    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    if (envelope['ok'] != true)
      throw StateError(envelope['pesan'] as String? ?? 'Terjadi kesalahan.');
    return Map<String, dynamic>.from(envelope['result'] as Map);
  }

  @override
  Future<Map<String, dynamic>> preferences() async => Map<String, dynamic>.from(
    await _channel.invokeMethod<Map>('preferences') ?? const {},
  );
  @override
  Future<void> savePreferences({
    required bool dark,
    required bool hideBudget,
  }) async {
    final saved = await _channel.invokeMethod<bool>('savePreferences', {
      'dark': dark,
      'hideBudget': hideBudget,
    });
    if (saved != true) throw StateError('Pengaturan gagal disimpan.');
  }
}

String errorText(Object error) => error is StateError
    ? error.message.toString()
    : error is PlatformException
    ? error.message ?? 'Penyimpanan tidak dapat diakses.'
    : 'Terjadi kesalahan. Silakan coba lagi.';

class AppController extends ChangeNotifier {
  final LocalApi api;
  FinanceData data = const FinanceData();
  bool loading = true,
      unlocked = false,
      needsSetup = true,
      dark = false,
      hideBudget = false;
  String? startupError;
  AppController(this.api);

  Future<void> initialize() async {
    loading = true;
    startupError = null;
    notifyListeners();
    try {
      final preferences = await api.preferences();
      dark = preferences['dark'] == true;
      hideBudget = preferences['hideBudget'] == true;
      final state = await api.request('/api/pin/status');
      needsSetup = state['perlu_setup'] == true;
      // Display the gate unless a valid local session already exists.
      if (state['terbuka'] == true && !needsSetup) {
        data = FinanceData.fromJson(await api.request('/api/data'));
        unlocked = true;
      }
    } catch (e) {
      startupError = errorText(e);
    }
    loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> authenticate(
    String mode,
    String pin, [
    String recovery = '',
  ]) {
    return api.request(
      '/api/pin/${mode == 'reset' ? 'reset' : mode}',
      method: 'POST',
      body: mode == 'reset'
          ? {'pin_baru': pin, 'kode_pemulihan': recovery}
          : {'pin': pin},
    );
  }

  Future<void> open() async {
    data = FinanceData.fromJson(await api.request('/api/data'));
    needsSetup = false;
    unlocked = true;
    notifyListeners();
  }

  Future<void> lock() async {
    await api.request('/api/pin/lock', method: 'POST');
    data = const FinanceData();
    unlocked = false;
    needsSetup = false;
    notifyListeners();
  }

  Future<String> mutate(
    String path,
    String method,
    Map<String, dynamic> body,
  ) async {
    final response = await api.request(path, method: method, body: body);
    data = FinanceData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    notifyListeners();
    return response['pesan'] as String;
  }

  Future<String> delete(FinanceEntry entry) => mutate(
    '/api/${entry.income ? 'pemasukan' : 'pengeluaran'}/${entry.id}',
    'DELETE',
    {},
  );
  Future<void> _preferenceQueue = Future<void>.value();
  Future<void> _togglePreference({required bool theme}) {
    final operation = _preferenceQueue.then((_) async {
      final nextDark = theme ? !dark : dark;
      final nextHidden = theme ? hideBudget : !hideBudget;
      await api.savePreferences(dark: nextDark, hideBudget: nextHidden);
      dark = nextDark;
      hideBudget = nextHidden;
      notifyListeners();
    });
    // Keep subsequent taps usable after a failed disk write.
    _preferenceQueue = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> toggleDark() => _togglePreference(theme: true);
  Future<void> toggleHidden() => _togglePreference(theme: false);
}
