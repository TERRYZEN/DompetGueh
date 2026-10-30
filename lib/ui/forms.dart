import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/models.dart';
import 'common.dart';
import 'theme.dart';

Future<String?> showEntryForm(
  BuildContext context,
  AppController controller, {
  String type = 'pengeluaran',
}) => showDialog<String>(
  context: context,
  builder: (_) => _EntryDialog(controller: controller, initialType: type),
);

class _EntryDialog extends StatefulWidget {
  final AppController controller;
  final String initialType;
  const _EntryDialog({required this.controller, required this.initialType});
  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final form = GlobalKey<FormState>();
  final expenseName = TextEditingController(),
      incomeName = TextEditingController();
  final expenseAmount = TextEditingController(),
      incomeAmount = TextEditingController(),
      budgetAmount = TextEditingController();
  late String type;
  String expenseCategory = 'Makanan',
      incomeCategory = 'Gaji',
      budgetMode = 'tambah';
  DateTime expenseDate = DateTime.now(), incomeDate = DateTime.now();
  bool busy = false;
  String error = '';
  @override
  void initState() {
    super.initState();
    type = widget.initialType;
  }

  @override
  void dispose() {
    for (final c in [
      expenseName,
      incomeName,
      expenseAmount,
      incomeAmount,
      budgetAmount,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController get amount => type == 'anggaran'
      ? budgetAmount
      : type == 'pemasukan'
      ? incomeAmount
      : expenseAmount;
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final value = int.parse(amount.text.replaceAll('.', ''));
      final String message;
      if (type == 'anggaran') {
        message = await widget.controller.mutate('/api/anggaran', 'PUT', {
          'anggaran': value,
          'mode': budgetMode,
        });
      } else {
        final income = type == 'pemasukan';
        message = await widget.controller.mutate('/api/$type', 'POST', {
          'nama': (income ? incomeName : expenseName).text.trim(),
          'tanggal': dateValue(income ? incomeDate : expenseDate),
          'kategori': income ? incomeCategory : expenseCategory,
          'jumlah': value,
        });
      }
      if (mounted) Navigator.pop(context, message);
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final income = type == 'pemasukan';
    final budget = type == 'anggaran';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow('DATA KEUANGAN BARU'),
                          const SizedBox(height: 6),
                          Text('Tambah Data', style: heading(19)),
                          const SizedBox(height: 6),
                          Text(
                            'Pilih jenis data yang ingin kamu catat.',
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const FormLabel('Jenis data'),
                DropdownButtonFormField<String>(
                  key: const Key('entry-type'),
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(
                      value: 'pengeluaran',
                      child: Text('Tambahkan Pengeluaran'),
                    ),
                    DropdownMenuItem(
                      value: 'pemasukan',
                      child: Text('Tambahkan Pemasukan'),
                    ),
                    DropdownMenuItem(
                      value: 'anggaran',
                      child: Text('Tambahkan Anggaran'),
                    ),
                  ],
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    color: c.text,
                  ),
                  isExpanded: true,
                  onChanged: busy
                      ? null
                      : (v) {
                          if (v != null)
                            setState(() {
                              type = v;
                              error = '';
                            });
                        },
                ),
                const SizedBox(height: 18),
                if (!budget) ...[
                  FormLabel(income ? 'Nama pemasukan' : 'Nama pengeluaran'),
                  TextFormField(
                    key: ValueKey('name-$type'),
                    controller: income ? incomeName : expenseName,
                    enabled: !busy,
                    maxLength: 100,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: income
                          ? 'Contoh: Gaji bulanan'
                          : 'Contoh: Makan siang',
                      counterText: '',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nama wajib diisi.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  const FormLabel('Tanggal'),
                  InkWell(
                    key: const Key('entry-date'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: busy
                        ? null
                        : () async {
                            final next = await showDatePicker(
                              context: context,
                              initialDate: income ? incomeDate : expenseDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(9999),
                              helpText: 'Pilih tanggal',
                              cancelText: 'Batal',
                              confirmText: 'Pilih',
                            );
                            if (next != null && mounted)
                              setState(() {
                                if (income) {
                                  incomeDate = next;
                                } else {
                                  expenseDate = next;
                                }
                              });
                          },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                      ),
                      child: Text(
                        displayDate(
                          dateValue(income ? incomeDate : expenseDate),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FormLabel(income ? 'Sumber' : 'Kategori'),
                  DropdownButtonFormField<String>(
                    key: ValueKey('category-$type'),
                    initialValue: income ? incomeCategory : expenseCategory,
                    items: (income ? incomeCategories : expenseCategories)
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      color: c.text,
                    ),
                    onChanged: busy
                        ? null
                        : (v) {
                            if (v != null)
                              setState(() {
                                if (income) {
                                  incomeCategory = v;
                                } else {
                                  expenseCategory = v;
                                }
                              });
                          },
                  ),
                  const SizedBox(height: 18),
                  if (income) ...[
                    Text(
                      'Pemasukan yang disimpan otomatis menambah anggaran bulanan.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ] else ...[
                  const FormLabel('Cara menyimpan anggaran'),
                  DropdownButtonFormField<String>(
                    key: const Key('budget-mode'),
                    initialValue: budgetMode,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'tambah',
                        child: Text('Tambahkan ke anggaran sebelumnya'),
                      ),
                      DropdownMenuItem(
                        value: 'ganti',
                        child: Text('Ganti total anggaran'),
                      ),
                    ],
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: c.text,
                    ),
                    onChanged: busy
                        ? null
                        : (v) {
                            if (v != null) setState(() => budgetMode = v);
                          },
                  ),
                  const SizedBox(height: 18),
                ],
                FormLabel(
                  budget
                      ? 'Jumlah anggaran (Rupiah)'
                      : income
                      ? 'Jumlah pemasukan (Rupiah)'
                      : 'Jumlah pengeluaran (Rupiah)',
                ),
                TextFormField(
                  key: ValueKey('amount-$type'),
                  controller: amount,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    prefixText: 'Rp  ',
                    hintText: budget || income ? '5.000.000' : '25.000',
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').replaceAll('.', ''));
                    if (n == null || n > 9007199254740991)
                      return 'Masukkan nominal yang valid.';
                    if (n < (budget ? 0 : 1))
                      return budget
                          ? 'Anggaran harus nol atau lebih.'
                          : 'Jumlah harus lebih dari Rp0.';
                    return null;
                  },
                ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: Color(0xffdf5967),
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: busy ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      key: const Key('save-entry'),
                      onPressed: busy ? null : save,
                      child: Text(busy ? 'Menyimpan...' : 'Simpan Data'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> showProfileForm(
  BuildContext context,
  AppController controller,
) => showDialog<String>(
  context: context,
  builder: (_) => _ProfileDialog(controller),
);

class _ProfileDialog extends StatefulWidget {
  final AppController controller;
  const _ProfileDialog(this.controller);
  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final name = TextEditingController(text: widget.controller.data.name);
  final form = GlobalKey<FormState>();
  bool busy = false;
  String error = '';
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final message = await widget.controller.mutate('/api/profil', 'PUT', {
        'nama': name.text.trim(),
      });
      if (mounted) Navigator.pop(context, message);
    } catch (e) {
      if (mounted) setState(() => error = errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: context.palette.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    title: Text('Ubah Nama Pengguna', style: heading(19)),
    content: SizedBox(
      width: 360,
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FormLabel('Nama pengguna'),
            TextFormField(
              key: const Key('profile-name-input'),
              controller: name,
              maxLength: 40,
              enabled: !busy,
              decoration: const InputDecoration(hintText: 'Nama kamu'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Nama tidak boleh kosong.'
                  : null,
              onFieldSubmitted: (_) {
                if (!busy) save();
              },
            ),
            if (error.isNotEmpty)
              Text(
                error,
                style: const TextStyle(fontSize: 12, color: Color(0xffdf5967)),
              ),
          ],
        ),
      ),
    ),
    actions: [
      OutlinedButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      ElevatedButton(
        key: const Key('save-profile'),
        onPressed: busy ? null : save,
        child: Text(busy ? 'Menyimpan...' : 'Simpan Nama'),
      ),
    ],
  );
}
