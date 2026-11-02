import 'package:dompetgueh_flutter/core/controller.dart';

const recoveryCode = 'ABCD-1234-ABCD-1234-ABCD-1234';
const replacementCode = 'ABCD-5678-ABCD-5678-ABCD-5678';

Map<String, dynamic> fixtureData() => {
  'anggaran': 6000000,
  'nama_pengguna': 'Terry',
  'pemasukan': [
    {
      'id': 1,
      'nama': 'Gaji bulanan',
      'tanggal': '${DateTime.now().year}-10-01',
      'kategori': 'Gaji',
      'jumlah': 5000000,
      'ditambahkan_ke_anggaran': true,
    },
  ],
  'pengeluaran': [
    {
      'id': 2,
      'nama': 'Makan siang',
      'tanggal': '${DateTime.now().year}-10-02',
      'kategori': 'Makanan',
      'jumlah': 25000,
    },
  ],
};

/// UI fixtures: fixed responses only; actual banking/PIN rules live in FinanceEngine.
class FixtureApi implements LocalApi {
  Map<String, dynamic> data = fixtureData();
  final List<({String path, String method, Map<String, dynamic> body})> calls =
      [];
  bool unlocked, setup, dark = false, hidden = false, failSave = false;
  String pin = '1234';
  FixtureApi({this.unlocked = true, this.setup = false});

  @override
  Future<Map<String, dynamic>> preferences() async => {
    'dark': dark,
    'hideBudget': hidden,
  };
  @override
  Future<void> savePreferences({
    required bool dark,
    required bool hideBudget,
  }) async {
    if (failSave) throw StateError('Pengaturan gagal disimpan.');
    this.dark = dark;
    hidden = hideBudget;
  }

  @override
  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic> body = const {},
  }) async {
    calls.add((path: path, method: method, body: body));
    switch (path) {
      case '/api/pin/status':
        return {'perlu_setup': setup, 'terbuka': unlocked};
      case '/api/pin/setup':
        setup = false;
        unlocked = true;
        return {'kode_pemulihan': recoveryCode};
      case '/api/pin/unlock':
        if (body['pin'] != pin)
          throw StateError('PIN salah. Silakan coba lagi.');
        unlocked = true;
        return {'pesan': 'Aplikasi berhasil dibuka.'};
      case '/api/pin/reset':
        if (body['kode_pemulihan'] != recoveryCode)
          throw StateError('Kode pemulihan salah atau tidak tersedia.');
        pin = body['pin_baru'];
        unlocked = true;
        return {'kode_pemulihan': replacementCode};
      case '/api/pin/lock':
        unlocked = false;
        return {'pesan': 'Aplikasi dikunci.'};
      case '/api/data':
        return data;
      case '/api/profil':
        data = {...data, 'nama_pengguna': body['nama']};
        return {'pesan': 'Nama berhasil diperbarui.', 'data': data};
      case '/api/pemasukan':
        data = {
          ...data,
          'anggaran': 6125000,
          'pemasukan': [
            ...data['pemasukan'],
            {
              'id': 3,
              'nama': 'Bonus offline',
              'tanggal': '${DateTime.now().year}-10-30',
              'kategori': 'Gaji',
              'jumlah': 125000,
              'ditambahkan_ke_anggaran': true,
            },
          ],
        };
        return {'pesan': 'Pemasukan berhasil ditambahkan.', 'data': data};
      case '/api/pengeluaran/2':
        data = {...data, 'pengeluaran': <Map<String, dynamic>>[]};
        return {'pesan': 'Pengeluaran berhasil dihapus.', 'data': data};
      default:
        throw StateError('Fixture tidak tersedia: $method $path');
    }
  }
}
