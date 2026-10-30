import 'package:flutter/material.dart';
import '../core/models.dart';
import 'chart.dart';
import 'common.dart';
import 'theme.dart';

class HistoryView extends StatelessWidget {
  final FinanceData data;
  final int year;
  final String type;
  final ValueChanged<int> onYear;
  final ValueChanged<String> onType;
  final ValueChanged<FinanceEntry> onDelete;
  final VoidCallback onAdd;
  const HistoryView({
    super.key,
    required this.data,
    required this.year,
    required this.type,
    required this.onYear,
    required this.onType,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final years = {
      DateTime.now().year,
      year,
      ...data.history.map((e) => e.year),
    }.toList()..sort((a, b) => b.compareTo(a));
    final entries = data.history
        .where(
          (e) =>
              e.year == year &&
              (type == 'semua' || (type == 'pemasukan') == e.income),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Grafik Pemasukan & Pengeluaran', style: heading(15)),
              const SizedBox(height: 5),
              Text(
                'Perbandingan tiap bulan dalam satu tahun',
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
              const SizedBox(height: 20),
              HistoryChart(data: data, year: year),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Histori Keuangan', style: heading(16)),
                    const SizedBox(height: 5),
                    Text(
                      'Pemasukan dan pengeluaran yang udah lu catat',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _Filter<String>(
                            widgetKey: const Key('history-type'),
                            value: type,
                            values: const {
                              'semua': 'Semua',
                              'pemasukan': 'Pemasukan',
                              'pengeluaran': 'Pengeluaran',
                            },
                            onChanged: onType,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: _Filter<int>(
                            widgetKey: const Key('history-year'),
                            value: year,
                            values: {for (final y in years) y: y.toString()},
                            onChanged: onYear,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: c.soft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entries.length} data',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 35,
                    horizontal: 12,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: c.soft,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.north_east, color: primary),
                      ),
                      const SizedBox(height: 14),
                      Text('Belum ada transaksi', style: heading(14)),
                      const SizedBox(height: 6),
                      Text(
                        data.history.isEmpty
                            ? 'Mulai catat pemasukan atau pengeluaran pertamamu.'
                            : 'Tidak ada transaksi untuk filter ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onAdd,
                        child: const Text('＋ Tambah transaksi'),
                      ),
                    ],
                  ),
                ),
              ...entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TransactionTile(
                    entry: e,
                    onDelete: () => onDelete(e),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Filter<T> extends StatelessWidget {
  final T value;
  final Map<T, String> values;
  final ValueChanged<T> onChanged;
  final Key widgetKey;
  const _Filter({
    required this.widgetKey,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    height: 41,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: context.palette.surface,
      border: Border.all(color: context.palette.line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        key: widgetKey,
        value: value,
        isExpanded: true,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          color: context.palette.text,
        ),
        items: values.entries
            .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ),
  );
}

class _TransactionTile extends StatelessWidget {
  final FinanceEntry entry;
  final VoidCallback onDelete;
  const _TransactionTile({required this.entry, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final style = categoryStyles[entry.category] ?? categoryStyles['Lainnya']!;
    return Container(
      key: Key('transaction-${entry.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 29,
                      height: 29,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(style.icon, size: 17, color: style.color),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          entry.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: entry.income ? green.withValues(alpha: .1) : c.soft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: entry.income ? green : primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayDate(entry.date),
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  '${entry.income ? '+' : '-'}${rupiah(entry.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: entry.income ? green : c.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              key: Key('delete-${entry.id}'),
              tooltip: 'Hapus ${entry.name}',
              onPressed: onDelete,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xffdf5967).withValues(alpha: .1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.close, color: Color(0xffdf5967), size: 23),
            ),
          ),
        ],
      ),
    );
  }
}
