import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/controller.dart';
import 'common.dart';
import 'theme.dart';

class AuthScreen extends StatefulWidget {
  final AppController controller;
  const AuthScreen({super.key, required this.controller});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _pin = TextEditingController(),
      _confirm = TextEditingController(),
      _recovery = TextEditingController();
  late String mode;
  bool busy = false;
  String error = '', code = '';
  @override
  void initState() {
    super.initState();
    mode = widget.controller.needsSetup ? 'setup' : 'unlock';
  }

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    _recovery.dispose();
    super.dispose();
  }

  void changeMode(String next) => setState(() {
    mode = next;
    error = '';
    code = '';
    _pin.clear();
    _confirm.clear();
    _recovery.clear();
  });

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (!RegExp(r'^\d{4,8}$').hasMatch(_pin.text)) {
      setState(() => error = 'PIN harus terdiri dari 4 sampai 8 angka.');
      return;
    }
    if (mode != 'unlock' && _pin.text != _confirm.text) {
      setState(() => error = 'Konfirmasi PIN tidak sama.');
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final result = await widget.controller.authenticate(
        mode,
        _pin.text,
        _recovery.text.trim(),
      );
      _pin.clear();
      _confirm.clear();
      _recovery.clear();
      if (mode == 'unlock') {
        await widget.controller.open();
      } else if (mounted) {
        setState(() => code = result['kode_pemulihan'] as String);
      }
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open() async {
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await widget.controller.open();
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final recovery = code.isNotEmpty;
    final title = recovery
        ? 'Simpan Kode Pemulihan'
        : mode == 'setup'
        ? 'Buat PIN Keamanan'
        : mode == 'reset'
        ? 'Buat PIN Baru'
        : 'Masukkan PIN';
    final description = recovery
        ? 'PIN berhasil dibuat. Simpan kode ini sebelum masuk aplikasi.'
        : mode == 'setup'
        ? 'Buat PIN 4–8 angka untuk melindungi data keuanganmu.'
        : mode == 'reset'
        ? 'Masukkan kode pemulihan yang kamu simpan, kemudian buat PIN baru.'
        : 'Masukkan PIN keamanan untuk membuka DompetGueh.';
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c.dark
                ? [c.bg, const Color(0xff161c33)]
                : [c.bg, const Color(0xffeaf2ff)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (bounds.maxHeight - 40).clamp(0, double.infinity),
                ),
                child: Center(
                  child: Container(
                    width: 390,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 27,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      border: Border.all(color: c.line),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 60,
                          offset: const Offset(0, 25),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Brand(large: true),
                        const SizedBox(height: 22),
                        const Eyebrow('DOMPETGUEH • KEUANGAN PRIBADI'),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          key: const Key('auth-title'),
                          style: heading(27),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 25),
                        if (recovery) ...[
                          Text(
                            'Simpan kode pemulihan ini bener bener. Kode cuman ditampilkan sekali dan diperlukan kalo lu lupa PIN.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.bg,
                              border: Border.all(color: primary),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: SelectableText(
                              code,
                              key: const Key('recovery-code'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                height: 1.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              key: const Key('copy-recovery'),
                              onPressed: () async {
                                try {
                                  await Clipboard.setData(
                                    ClipboardData(text: code),
                                  );
                                  if (context.mounted)
                                    toast(context, 'Kode pemulihan disalin.');
                                } catch (_) {
                                  if (context.mounted)
                                    toast(
                                      context,
                                      'Silakan salin kode secara manual.',
                                      error: true,
                                    );
                                }
                              },
                              child: const Text('Salin Kode'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              key: const Key('finish-recovery'),
                              onPressed: busy ? null : open,
                              child: Text(
                                busy
                                    ? 'Membuka...'
                                    : 'Sudah Disimpan — Buka Aplikasi',
                              ),
                            ),
                          ),
                        ] else ...[
                          if (mode == 'reset') ...[
                            const FormLabel('Kode pemulihan'),
                            TextField(
                              key: const Key('recovery-input'),
                              controller: _recovery,
                              enabled: !busy,
                              maxLength: 40,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 17),
                          ],
                          FormLabel(
                            mode == 'unlock' ? 'PIN keamanan' : 'PIN baru',
                          ),
                          TextField(
                            key: const Key('pin-input'),
                            controller: _pin,
                            obscureText: true,
                            enabled: !busy,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                            ],
                            style: const TextStyle(
                              fontSize: 16,
                              letterSpacing: 3,
                            ),
                            decoration: const InputDecoration(
                              hintText: '4–8 angka',
                            ),
                            onSubmitted: (_) {
                              if (mode == 'unlock' && !busy) submit();
                            },
                          ),
                          const SizedBox(height: 17),
                          if (mode != 'unlock') ...[
                            const FormLabel('Ulangi PIN baru'),
                            TextField(
                              key: const Key('confirm-pin'),
                              controller: _confirm,
                              obscureText: true,
                              enabled: !busy,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(8),
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                letterSpacing: 3,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Ulangi PIN',
                              ),
                              onSubmitted: (_) {
                                if (!busy) submit();
                              },
                            ),
                            const SizedBox(height: 17),
                          ],
                          if (error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                error,
                                key: const Key('auth-error'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xffdf5967),
                                ),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              key: const Key('submit-pin'),
                              onPressed: busy ? null : submit,
                              child: Text(
                                busy
                                    ? 'Memproses...'
                                    : mode == 'setup'
                                    ? 'Simpan PIN'
                                    : mode == 'reset'
                                    ? 'Buat PIN Baru'
                                    : 'Buka Aplikasi',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (mode == 'unlock')
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                key: const Key('forgot-pin'),
                                onPressed: busy
                                    ? null
                                    : () => changeMode('reset'),
                                child: const Text('Lupa PIN?'),
                              ),
                            ),
                          if (mode == 'reset')
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: busy
                                    ? null
                                    : () => changeMode('unlock'),
                                child: const Text('Kembali ke Masuk PIN'),
                              ),
                            ),
                          Center(
                            child: Text(
                              'PIN harus terdiri dari 4–8 angka.',
                              style: TextStyle(fontSize: 11, color: c.muted),
                            ),
                          ),
                        ],
                        if (recovery && error.isNotEmpty)
                          Text(
                            error,
                            style: const TextStyle(
                              color: Color(0xffdf5967),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
