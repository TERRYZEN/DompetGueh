import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/models.dart';
import 'common.dart';
import 'theme.dart';
import 'visuals.dart';
import 'glass_select.dart';

class EntryDraft {
  String expenseName = '',
      incomeName = '',
      expenseAmount = '',
      incomeAmount = '',
      budgetAmount = '';
  String expenseCategory = 'Makanan',
      incomeCategory = 'Gaji',
      budgetMode = 'tambah';
  DateTime expenseDate = DateTime.now(), incomeDate = DateTime.now();
  void reset() {
    expenseName = '';
    incomeName = '';
    expenseAmount = '';
    incomeAmount = '';
    budgetAmount = '';
    expenseCategory = 'Makanan';
    incomeCategory = 'Gaji';
    budgetMode = 'tambah';
    expenseDate = DateTime.now();
    incomeDate = DateTime.now();
  }
}

Future<String?> showEntryForm(
  BuildContext context,
  AppController controller, {
  String type = 'pengeluaran',
  EntryDraft? draft,
}) => showAppDialog<String>(
  context,
  (_) => _EntryDialog(controller: controller, initialType: type, draft: draft),
);

class _EntryDialog extends StatefulWidget {
  final AppController controller;
  final String initialType;
  final EntryDraft? draft;
  const _EntryDialog({
    required this.controller,
    required this.initialType,
    this.draft,
  });
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
  bool completed = false;
  @override
  void initState() {
    super.initState();
    type = widget.initialType;
    final d = widget.draft;
    if (d != null) {
      expenseName.text = d.expenseName;
      incomeName.text = d.incomeName;
      expenseAmount.text = d.expenseAmount;
      incomeAmount.text = d.incomeAmount;
      budgetAmount.text = d.budgetAmount;
      expenseCategory = d.expenseCategory;
      incomeCategory = d.incomeCategory;
      budgetMode = d.budgetMode;
      expenseDate = d.expenseDate;
      incomeDate = d.incomeDate;
    }
  }

  @override
  void dispose() {
    captureDraft();
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

  void captureDraft() {
    final d = widget.draft;
    if (d == null || completed) return;
    d.expenseName = expenseName.text;
    d.incomeName = incomeName.text;
    d.expenseAmount = expenseAmount.text;
    d.incomeAmount = incomeAmount.text;
    d.budgetAmount = budgetAmount.text;
    d.expenseCategory = expenseCategory;
    d.incomeCategory = incomeCategory;
    d.budgetMode = budgetMode;
    d.expenseDate = expenseDate;
    d.incomeDate = incomeDate;
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
      if (mounted) captureDraft();
      if (type == 'anggaran') {
        widget.draft?.budgetAmount = '';
      } else {
        widget.draft?.reset();
      }
      completed = true;
      await WidgetsBinding.instance.endOfFrame;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: NotificationListener<ScrollNotification>(
          onNotification: (_) {
            GlassSelect.closeAll();
            return false;
          },
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
                            Text(
                              budget
                                  ? 'Tambah Anggaran'
                                  : income
                                  ? 'Tambah Pemasukan'
                                  : 'Tambah Pengeluaran',
                              style: heading(19),
                            ),
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
                  GlassSelect<String>(
                    key: const Key('entry-type'),
                    value: type,
                    enabled: !busy,
                    options: const {
                      'pengeluaran': 'Tambahkan Pengeluaran',
                      'pemasukan': 'Tambahkan Pemasukan',
                      'anggaran': 'Tambahkan Anggaran',
                    },
                    descriptions: const {
                      'pengeluaran': 'Catat uang yang keluar',
                      'pemasukan': 'Catat uang yang masuk',
                      'anggaran': 'Atur anggaranmu',
                    },
                    onChanged: (v) => setState(() {
                      type = v;
                      error = '';
                    }),
                  ),
                  const SizedBox(height: 18),
                  if (!budget) ...[
                    FormLabel(income ? 'Nama pemasukan' : 'Nama pengeluaran'),
                    TextFormField(
                      key: ValueKey('name-$type'),
                      controller: income ? incomeName : expenseName,
                      enabled: !busy,
                      maxLength: 100,
                      style: const TextStyle(fontSize: 12),
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
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FormLabel(income ? 'Sumber' : 'Kategori'),
                    GlassSelect<String>(
                      key: ValueKey('category-$type'),
                      value: income ? incomeCategory : expenseCategory,
                      enabled: !busy,
                      options: {
                        for (final s
                            in (income ? incomeCategories : expenseCategories))
                          s: s,
                      },
                      onChanged: (v) => setState(() {
                        if (income) {
                          incomeCategory = v;
                        } else {
                          expenseCategory = v;
                        }
                      }),
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
                    GlassSelect<String>(
                      key: const Key('budget-mode'),
                      value: budgetMode,
                      enabled: !busy,
                      options: const {
                        'tambah': 'Tambahkan ke anggaran sebelumnya',
                        'ganti': 'Ganti total anggaran',
                      },
                      onChanged: (v) => setState(() => budgetMode = v),
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
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      prefixText: 'Rp  ',
                      hintText: budget
                          ? '500.000'
                          : income
                          ? '5.000.000'
                          : '25.000',
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
                      PressScale(
                        child: ElevatedButton(
                          key: const Key('save-entry'),
                          onPressed: busy ? null : save,
                          child: Text(
                            busy
                                ? 'Menyimpan...'
                                : budget
                                ? 'Simpan Anggaran ↗'
                                : income
                                ? 'Simpan Pemasukan ↗'
                                : 'Simpan Pengeluaran ↗',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
) => showAppDialog<String>(context, (_) => _ProfileDialog(controller));

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
      await WidgetsBinding.instance.endOfFrame;
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('PROFIL'),
        const SizedBox(height: 7),
        Text('Ubah Nama', style: heading(19)),
        const SizedBox(height: 6),
        Text(
          'Nama ini yang bakalan tampil di dashboard.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: context.palette.muted,
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: 360,
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FormLabel('Nama lu'),
            TextFormField(
              key: const Key('profile-name-input'),
              controller: name,
              maxLength: 40,
              enabled: !busy,
              decoration: const InputDecoration(
                hintText: 'Contoh: Budi Santoso',
              ),
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
      PressScale(
        child: ElevatedButton(
          key: const Key('save-profile'),
          onPressed: busy ? null : save,
          child: Text(busy ? 'Menyimpan...' : 'Simpan Nama'),
        ),
      ),
    ],
  );
}
