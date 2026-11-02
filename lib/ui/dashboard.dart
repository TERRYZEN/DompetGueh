import 'package:flutter/material.dart';
import '../core/models.dart';
import 'common.dart';
import 'theme.dart';
import 'visuals.dart';

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
    final c = context.palette, w = MediaQuery.sizeOf(context).width;
    final mobile = w <= 760, tiny = w < 360;
    final budgetSize = mobile
        ? (w * .08).clamp(27.0, 40.0)
        : (w * .042).clamp(32.0, 52.0);
    final remainingSize = mobile ? 20.0 : (w * .022).clamp(19.0, 26.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSurface(
          key: const Key('finance-overview'),
          radius: mobile ? 26 : 30,
          padding: EdgeInsets.all(
            tiny
                ? 16
                : mobile
                ? 20
                : 30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                key: const Key('budget-heading'),
                children: [
                  Container(
                    width: mobile ? 34 : 40,
                    height: mobile ? 34 : 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.soft,
                      borderRadius: BorderRadius.circular(mobile ? 11 : 13),
                    ),
                    child: const DgIcon(DgSymbol.wallet, color: primary),
                  ),
                  SizedBox(width: mobile ? 10 : 12),
                  Expanded(
                    child: Text(
                      'ANGGARAN BULANAN',
                      style: TextStyle(
                        fontSize: mobile ? 11 : 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: mobile ? 0.8 : 1.3,
                        color: c.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onHorizontalDragUpdate: (_) {},
                    child: PressScale(
                      child: SizedBox(
                        width: mobile ? 40 : null,
                        height: mobile ? 40 : 44,
                        child: OutlinedButton(
                          key: const Key('edit-budget'),
                          onPressed: onBudget,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: mobile ? 8 : 12,
                            ),
                            minimumSize: Size(
                              mobile ? 40 : 0,
                              mobile ? 40 : 44,
                            ),
                            backgroundColor: c.glassInset,
                            side: BorderSide(color: c.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DgIcon(DgSymbol.edit, size: 17, color: c.muted),
                              if (!mobile) ...[
                                const SizedBox(width: 7),
                                Text(
                                  'Ubah',
                                  style: TextStyle(
                                    color: c.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: mobile ? 20 : 22),
              SizedBox(
                height: budgetSize * 1.25,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hidden ? 'Rp••••••' : rupiah(data.budget),
                      key: const Key('budget-value'),
                      style: heading(
                        budgetSize,
                      ).copyWith(height: 1.25, letterSpacing: -1.5),
                    ),
                  ),
                ),
              ),
              SizedBox(height: mobile ? 22 : 26),
              Container(
                key: const Key('remaining-card'),
                padding: EdgeInsets.symmetric(
                  horizontal: mobile ? 16 : 22,
                  vertical: mobile ? 16 : 20,
                ),
                decoration: BoxDecoration(
                  color: c.glassInset,
                  border: Border.all(color: c.glassBorder),
                  borderRadius: BorderRadius.circular(mobile ? 17 : 20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (tiny) ...[
                      Text(
                        'Sisa Anggaran',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.muted,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RemainingValue(
                        data: data,
                        hidden: hidden,
                        size: remainingSize,
                        align: Alignment.centerLeft,
                      ),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: mobile ? 3 : 0),
                            child: Text(
                              'Sisa Anggaran',
                              style: TextStyle(
                                fontSize: mobile ? 12 : 13,
                                height: 4 / 3,
                                color: c.muted,
                              ),
                            ),
                          ),
                          SizedBox(width: mobile ? 12 : 16),
                          Expanded(
                            child: _RemainingValue(
                              data: data,
                              hidden: hidden,
                              size: remainingSize,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 15),
                    BudgetProgress(
                      key: const Key('budget-progress'),
                      percent: data.percent,
                      hidden: hidden,
                      overBudget: data.remaining < 0,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 18,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 1),
                        child: Text(
                          hidden
                              ? '•••% anggaran terpakai'
                              : '${data.percent.round()}% anggaran terpakai',
                          key: const Key('progress-label'),
                          style: TextStyle(
                            fontSize: 11,
                            height: 14 / 11,
                            color: c.muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mobile ? 12 : 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _Metric(
                        income: true,
                        value: data.totalIncome,
                        count: data.incomes.length,
                      ),
                    ),
                    SizedBox(width: mobile ? 10 : 16),
                    Expanded(
                      child: _Metric(
                        income: false,
                        value: data.totalExpense,
                        count: data.expenses.length,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        CategoriesPanel(data: data),
      ],
    );
  }
}

class _RemainingValue extends StatelessWidget {
  final FinanceData data;
  final bool hidden;
  final double size;
  final Alignment align;
  const _RemainingValue({
    required this.data,
    required this.hidden,
    required this.size,
    this.align = Alignment.centerRight,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: size * 1.35,
    child: Align(
      alignment: align,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: align,
        child: Text(
          hidden ? 'Rp••••••' : rupiah(data.remaining),
          key: const Key('remaining-value'),
          style: heading(
            size,
            color: !hidden && data.remaining < 0
                ? context.palette.expense
                : null,
          ).copyWith(height: 1.35, letterSpacing: 0),
        ),
      ),
    ),
  );
}

class _Metric extends StatefulWidget {
  final bool income;
  final int value, count;
  const _Metric({
    required this.income,
    required this.value,
    required this.count,
  });
  @override
  State<_Metric> createState() => _MetricState();
}

class _MetricState extends State<_Metric> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final c = context.palette,
        w = MediaQuery.sizeOf(context).width,
        mobile = w <= 760,
        tiny = w < 360;
    final color = widget.income ? c.income : c.expense;
    final size = mobile
        ? (w * .04).clamp(15.0, 22.0)
        : (w * .026).clamp(20.0, 30.0);
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        key: Key(widget.income ? 'income-card' : 'expense-card'),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: cssEase,
        transform: Matrix4.translationValues(0, hover ? -2 : 0, 0),
        padding: EdgeInsets.symmetric(
          horizontal: tiny
              ? 10
              : mobile
              ? 13
              : 22,
          vertical: tiny
              ? 14
              : mobile
              ? 15
              : 20,
        ),
        decoration: BoxDecoration(
          color: c.glassInset,
          border: Border.all(
            color: widget.income ? c.incomeBorder : c.expenseBorder,
          ),
          borderRadius: BorderRadius.circular(mobile ? 18 : 20),
          boxShadow: hover
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                SizedBox(width: mobile ? 6 : 8),
                Expanded(
                  child: Text(
                    widget.income ? 'Total Pemasukan' : 'Total Pengeluaran',
                    style: TextStyle(
                      fontSize: mobile ? 10 : 12,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: c.muted,
                    ),
                  ),
                ),
                if (!mobile)
                  Text(
                    widget.income ? '↙' : '↗',
                    style: TextStyle(
                      fontSize: 19,
                      color: c.muted.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
            SizedBox(height: mobile ? 14 : 12),
            SizedBox(
              height: size * 1.35,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    rupiah(widget.value),
                    key: Key(widget.income ? 'income-value' : 'expense-value'),
                    style: heading(size, color: color).copyWith(height: 1.35),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${widget.count} ${widget.income ? 'pemasukan' : 'transaksi'} tercatat',
              style: TextStyle(
                fontSize: mobile ? 10 : 11,
                height: mobile ? 1.5 : 1.3,
                color: c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoriesPanel extends StatelessWidget {
  final FinanceData data;
  const CategoriesPanel({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final totals = <String, int>{};
    for (final e in data.expenses) {
      totals.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Panel(
      key: const Key('category-panel'),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width <= 760 ? 14 : 23,
        vertical: MediaQuery.sizeOf(context).width <= 760 ? 17 : 23,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Kategori',
                      style: heading(16).copyWith(
                        fontWeight: FontWeight.w700,
                        height: 22 / 16,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ke mana uang lu pergi?',
                      style: TextStyle(
                        fontSize: 13,
                        height: 17 / 13,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.radio_button_checked, size: 18, color: c.muted),
            ],
          ),
          const SizedBox(height: 17),
          if (entries.isEmpty)
            Text(
              'Ringkasan akan muncul setelah kamu menambahkan transaksi.',
              style: TextStyle(fontSize: 12, height: 4 / 3, color: c.muted),
            ),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  categorySymbols[entries[i].key] ?? '✦',
                  style: const TextStyle(fontSize: 11, height: 14 / 11),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entries[i].key,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  rupiah(entries[i].value),
                  style: const TextStyle(
                    fontSize: 11,
                    height: 14 / 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 5,
                color: c.dark ? c.track : const Color(0xfff2f3f8),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: data.totalExpense > 0
                      ? entries[i].value / data.totalExpense
                      : 0,
                  child: Container(
                    height: 5,
                    color:
                        (categoryStyles[entries[i].key] ??
                                categoryStyles['Lainnya']!)
                            .color,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(height: 1, color: c.line),
          const SizedBox(height: 17),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total semua kategori',
                  style: TextStyle(fontSize: 10, height: 1.3, color: c.muted),
                ),
              ),
              Text(
                rupiah(data.totalExpense),
                style: const TextStyle(
                  fontSize: 12,
                  height: 4 / 3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
