import 'package:flutter/material.dart';
import '../core/models.dart';
import 'common.dart';
import 'theme.dart';

class DashboardView extends StatelessWidget {
  final FinanceData data;
  final bool hidden;
  final VoidCallback onBudget;
  const DashboardView({
    super.key,
    required this.data,
    required this.hidden,
    required this.onBudget,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final cards = [
      _StatCard(
        title: 'Anggaran Bulanan',
        icon: Icons.receipt_long_outlined,
        color: primary,
        amount: hidden ? 'Rp••••••' : rupiah(data.budget),
        amountKey: const Key('budget-value'),
        bottom: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'Batas pengeluaran lu',
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
            TextButton(
              key: const Key('edit-budget'),
              onPressed: onBudget,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Tambahkan / ubah ↗',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      _StatCard(
        title: 'Total Pemasukan',
        icon: Icons.south_rounded,
        color: green,
        amount: rupiah(data.totalIncome),
        amountKey: const Key('income-value'),
        bottom: _Status('${data.incomes.length} pemasukan tercatat', green),
      ),
      _StatCard(
        title: 'Total Pengeluaran',
        icon: Icons.north_east_rounded,
        color: orange,
        amount: rupiah(data.totalExpense),
        amountKey: const Key('expense-value'),
        bottom: _Status('${data.expenses.length} transaksi tercatat', orange),
      ),
      _StatCard(
        title: 'Sisa Anggaran',
        icon: Icons.trending_up,
        color: green,
        amount: hidden ? 'Rp••••••' : rupiah(data.remaining),
        amountKey: const Key('remaining-value'),
        valueColor: !hidden && data.remaining < 0
            ? const Color(0xffdf5967)
            : null,
        bottom: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Track(
              data.percent / 100,
              data.remaining < 0 ? const Color(0xffdf5967) : primary,
            ),
            const SizedBox(height: 10),
            Text(
              hidden
                  ? '•••% anggaran terpakai'
                  : '${data.percent.round()}% anggaran terpakai',
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
          ],
        ),
      ),
      _StatCard(
        title: 'Uang Keluar',
        icon: Icons.diamond_outlined,
        color: primary,
        amount: rupiah(data.totalExpense),
        amountKey: const Key('spent-value'),
        bottom: Text(
          'Jumlah uang yang telah dikeluarkan',
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 3
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map((w) => SizedBox(width: width, child: w))
                  .toList(),
            ),
            const SizedBox(height: 22),
            _Categories(data),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, amount;
  final IconData icon;
  final Color color;
  final Color? valueColor;
  final Widget bottom;
  final Key amountKey;
  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bottom,
    required this.amountKey,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.palette.muted,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              key: amountKey,
              style: heading(25, color: valueColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        bottom,
      ],
    ),
  );
}

class _Status extends StatelessWidget {
  final String text;
  final Color color;
  const _Status(this.text, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: context.palette.muted),
        ),
      ),
    ],
  );
}

class _Track extends StatelessWidget {
  final double value;
  final Color color;
  const _Track(this.value, this.color);
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Container(
      height: 5,
      color: context.palette.line,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0, 1),
        child: ColoredBox(color: color),
      ),
    ),
  );
}

class _Categories extends StatelessWidget {
  final FinanceData data;
  const _Categories(this.data);
  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final amounts = <String, int>{};
    for (final e in data.expenses) {
      amounts.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    final entries = amounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Ringkasan Kategori', style: heading(16))),
              const Icon(Icons.donut_large_rounded, size: 17, color: primary),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Ke mana uang lu pergi?',
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entries.isEmpty)
                  Text(
                    'Ringkasan akan muncul setelah kamu menambahkan transaksi.',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ...entries.map((e) {
                  final style =
                      categoryStyles[e.key] ?? categoryStyles['Lainnya']!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(style.icon, size: 15, color: style.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                rupiah(e.value),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _Track(
                          data.totalExpense > 0
                              ? e.value / data.totalExpense
                              : 0,
                          style.color,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Divider(color: c.line, height: 24),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total semua kategori',
                  style: TextStyle(fontSize: 11, color: c.muted),
                ),
              ),
              Text(
                rupiah(data.totalExpense),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
