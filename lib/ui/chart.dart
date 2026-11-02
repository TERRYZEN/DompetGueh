import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models.dart';
import 'theme.dart';

class HistoryChart extends StatelessWidget {
  final FinanceData data;
  final int year;
  const HistoryChart({super.key, required this.data, required this.year});
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Grafik pemasukan dan pengeluaran bulanan tahun $year. Hijau pemasukan, jingga pengeluaran.',
    child: SizedBox(
      height: MediaQuery.sizeOf(context).width <= 760 ? 210 : 260,
      width: double.infinity,
      child: CustomPaint(painter: _ChartPainter(data, year, context.palette)),
    ),
  );
}

class _ChartPainter extends CustomPainter {
  final FinanceData data;
  final int year;
  final Palette colors;
  _ChartPainter(this.data, this.year, this.colors);
  String compact(num value) {
    if (value >= 1000000)
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)} jt';
    if (value >= 1000) return '${(value / 1000).round()} rb';
    return value.round().toString();
  }

  void text(
    Canvas canvas,
    String value,
    Offset point, {
    bool right = false,
    bool center = false,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 10,
          color: colors.muted,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(
      canvas,
      point -
          Offset(
            right
                ? p.width
                : center
                ? p.width / 2
                : 0,
            p.height / 2,
          ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final income = List<double>.filled(12, 0),
        expense = List<double>.filled(12, 0);
    for (final item in data.history.where((e) => e.year == year)) {
      (item.income ? income : expense)[item.month - 1] += item.amount;
    }
    final maximum = [...income, ...expense, 1.0].reduce(math.max);
    const left = 44.0, top = 14.0;
    final width = math.max(0.0, size.width - left - 8),
        height = math.max(0.0, size.height - top - 26);
    final line = Paint()
      ..color = colors.line
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + height - height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - 8, y), line);
      text(canvas, compact(maximum * i / 4), Offset(left - 8, y), right: true);
    }
    final slot = width / 12, bar = math.min(16.0, width / 12 * .3);
    for (var i = 0; i < 12; i++) {
      final x = left + slot * i + slot / 2, bottom = top + height;
      final a = income[i] / maximum * height, b = expense[i] / maximum * height;
      canvas.drawRect(
        Rect.fromLTWH(x - bar - 2, bottom - a, bar, a),
        Paint()..color = green,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 2, bottom - b, bar, b),
        Paint()..color = orange,
      );
      text(canvas, monthNames[i], Offset(x, size.height - 11), center: true);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.year != year ||
      oldDelegate.colors.dark != colors.dark;
}
