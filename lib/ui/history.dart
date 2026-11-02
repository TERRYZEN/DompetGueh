import 'package:flutter/material.dart';
import '../core/models.dart';
import 'chart.dart';
import 'common.dart';
import 'theme.dart';
import 'visuals.dart';

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
  Widget title(BuildContext context, String headingText, String subtitle) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headingText,
            style: heading(16).copyWith(height: 22 / 16, letterSpacing: -.3),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 17 / 13,
              color: context.palette.muted,
            ),
          ),
        ],
      );
  @override
  Widget build(BuildContext context) {
    final c = context.palette, mobile = MediaQuery.sizeOf(context).width <= 760;
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
    final filters = Row(
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
        Expanded(
          child: _Filter<int>(
            widgetKey: const Key('history-year'),
            value: year,
            values: {for (final y in years) y: y.toString()},
            onChanged: onYear,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: c.dark ? const Color(0xff242a4a) : const Color(0xfff3f2ff),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '${entries.length} data',
            style: const TextStyle(
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 14 : 23,
            vertical: mobile ? 17 : 23,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: title(
                      context,
                      'Grafik Pemasukan & Pengeluaran',
                      'Perbandingan tiap bulan dalam satu tahun',
                    ),
                  ),
                  if (!mobile)
                    Row(
                      children: [
                        for (final item in [
                          (green, 'Pemasukan'),
                          (orange, 'Pengeluaran'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: item.$1,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.$2,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: mobile ? 17 : 22),
              HistoryChart(data: data, year: year),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 10 : 23,
            vertical: mobile ? 17 : 23,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: mobile ? 4 : 0),
                child: mobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title(
                            context,
                            'Histori Keuangan',
                            'Pemasukan dan pengeluaran yang udah lu catat',
                          ),
                          const SizedBox(height: 10),
                          filters,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: title(
                              context,
                              'Histori Keuangan',
                              'Pemasukan dan pengeluaran yang udah lu catat',
                            ),
                          ),
                          const SizedBox(width: 15),
                          SizedBox(width: 300, child: filters),
                        ],
                      ),
              ),
              SizedBox(height: mobile ? 17 : 22),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 34,
                    horizontal: 12,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.soft,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          '↗',
                          style: TextStyle(fontSize: 24, color: primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mulai catat pemasukan atau pengeluaran pertamamu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: c.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: onAdd,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '＋ Tambah transaksi',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                )
              else if (mobile)
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TransactionTile(
                      entry: e,
                      onDelete: () => onDelete(e),
                    ),
                  )
              else
                LayoutBuilder(
                  builder: (context, bounds) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: bounds.maxWidth),
                      child: DataTable(
                        columnSpacing: 24,
                        horizontalMargin: 0,
                        headingRowHeight: 26,
                        dataRowMinHeight: 62,
                        dataRowMaxHeight: 82,
                        dividerThickness: 1,
                        headingTextStyle: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .7,
                          color: Color(0xffa1a6b6),
                        ),
                        columns: [
                          for (final s in [
                            'TRANSAKSI',
                            'JENIS',
                            'KATEGORI',
                            'TANGGAL',
                            'JUMLAH',
                            '',
                          ])
                            DataColumn(label: Text(s)),
                        ],
                        rows: entries
                            .map(
                              (e) => DataRow(
                                cells: [
                                  DataCell(_Name(e, mobile: false)),
                                  DataCell(
                                    _Tag(
                                      e.income ? 'Pemasukan' : 'Pengeluaran',
                                      income: e.income,
                                      badge: true,
                                    ),
                                  ),
                                  DataCell(_Tag(e.category, income: e.income)),
                                  DataCell(
                                    Text(
                                      displayDate(e.date),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xff8a90a5),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${e.income ? '+' : '-'}${rupiah(e.amount)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: e.income ? green : c.text,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _Delete(
                                      e,
                                      () => onDelete(e),
                                      mobile: false,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
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
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragUpdate: (_) {},
    child: Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(
          color: context.palette.dark
              ? context.palette.line
              : const Color(0xffe7e9f1),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          key: widgetKey,
          value: value,
          isExpanded: true,
          icon: Icon(Icons.expand_more, size: 16, color: context.palette.text),
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.palette.text,
          ),
          items: values.entries
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    ),
  );
}

class _Name extends StatelessWidget {
  final FinanceEntry e;
  final bool mobile;
  const _Name(this.e, {required this.mobile});
  @override
  Widget build(BuildContext context) {
    final style = categoryStyles[e.category] ?? categoryStyles['Lainnya']!;
    final name = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          e.name,
          style: const TextStyle(
            fontSize: 11,
            height: 14 / 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          e.income ? 'Pemasukan' : 'Pengeluaran',
          style: const TextStyle(
            fontSize: 10,
            height: 1.3,
            color: Color(0xffa0a5b5),
          ),
        ),
      ],
    );
    return Row(
      mainAxisSize: mobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Container(
          width: mobile ? 29 : 34,
          height: mobile ? 29 : 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: style.color.withValues(alpha: 32 / 255),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            categorySymbols[e.category] ?? '✦',
            style: const TextStyle(fontSize: 15),
          ),
        ),
        SizedBox(width: mobile ? 7 : 10),
        if (mobile) Expanded(child: name) else name,
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool income, badge;
  const _Tag(this.text, {required this.income, this.badge = false});
  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: badge ? 5 : 6),
      decoration: BoxDecoration(
        color: income
            ? (c.dark ? const Color(0xff123229) : const Color(0xffe7f8f1))
            : badge
            ? (c.dark ? const Color(0xff3a2a17) : const Color(0xfffff2e6))
            : (c.dark ? const Color(0xff242a4a) : const Color(0xfff5f4ff)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          height: 1.3,
          fontWeight: badge ? FontWeight.w700 : FontWeight.w400,
          color: income
              ? (c.dark ? const Color(0xff3ddca6) : green)
              : badge
              ? orange
              : (c.dark ? const Color(0xff9d93ff) : const Color(0xff7063dc)),
        ),
      ),
    );
  }
}

class _Delete extends StatelessWidget {
  final FinanceEntry e;
  final VoidCallback onDelete;
  final bool mobile;
  const _Delete(this.e, this.onDelete, {required this.mobile});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragUpdate: (_) {},
    child: Tooltip(
      message: 'Hapus ${e.name}',
      child: PressScale(
        child: SizedBox(
          width: mobile ? 44 : 29,
          height: mobile ? 44 : 29,
          child: TextButton(
            key: Key('delete-${e.id}'),
            onPressed: onDelete,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              backgroundColor: context.palette.dark
                  ? const Color(0xff3a1f24)
                  : const Color(0xffffeef1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '×',
              style: TextStyle(
                fontSize: mobile ? 23 : 18,
                color: context.palette.dark
                    ? const Color(0xffff9299)
                    : const Color(0xffdf5967),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TransactionTile extends StatelessWidget {
  final FinanceEntry entry;
  final VoidCallback onDelete;
  const _TransactionTile({required this.entry, required this.onDelete});
  @override
  Widget build(BuildContext context) => Container(
    key: Key('transaction-${entry.id}'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: context.palette.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Name(entry, mobile: true),
              const SizedBox(height: 8),
              SizedBox(
                height: 28,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Tag(entry.category, income: entry.income),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayDate(entry.date),
                style: const TextStyle(
                  fontSize: 11,
                  height: 14 / 11,
                  color: Color(0xff8a90a5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${entry.income ? '+' : '-'}${rupiah(entry.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: entry.income ? green : context.palette.text,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Delete(entry, onDelete, mobile: true),
      ],
    ),
  );
}
