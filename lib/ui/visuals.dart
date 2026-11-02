import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'theme.dart';

const pageCurve = Cubic(.22, 1, .36, 1);
const cssEase = Cubic(.25, .1, .25, 1);

class AppBackdrop extends StatelessWidget {
  final Widget child;
  const AppBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BackdropPainter(context.palette.dark),
    child: child,
  );
}

class _BackdropPainter extends CustomPainter {
  final bool dark;
  _BackdropPainter(this.dark);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Palette(dark).bg, BlendMode.src);
    final gradients = [
      (
        const Offset(.08, .08),
        dark
            ? const Color.fromRGBO(44, 110, 150, .12)
            : const Color.fromRGBO(68, 144, 255, .12),
      ),
      (
        const Offset(.92, .45),
        dark
            ? const Color.fromRGBO(63, 82, 160, .10)
            : const Color.fromRGBO(100, 115, 255, .09),
      ),
    ];
    for (final (center, color) in gradients) {
      final point = Offset(center.dx * size.width, center.dy * size.height);
      final rx = math.max(center.dx, 1 - center.dx) * size.width * math.sqrt2;
      final ry = math.max(center.dy, 1 - center.dy) * size.height * math.sqrt2;
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.scale(rx, ry);
      canvas.drawRect(
        Rect.fromLTRB(
          -point.dx / rx,
          -point.dy / ry,
          (size.width - point.dx) / rx,
          (size.height - point.dy) / ry,
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            1,
            [color, color.withValues(alpha: 0)],
            [0, .48],
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

class GlassSurface extends StatelessWidget {
  final Widget child;
  final double radius, blur;
  final EdgeInsetsGeometry padding;
  final bool dock;
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 26,
    this.blur = 24,
    this.padding = EdgeInsets.zero,
    this.dock = false,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xff1f2f52,
            ).withValues(alpha: dock ? 0.16 : 0.07),
            blurRadius: dock ? 40 : 55,
            offset: Offset(0, dock ? 12 : 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: saturatedBlur(blur, dock ? 1.5 : 1.35),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: c.glassBorder),
              color: dock
                  ? (c.dark
                        ? const Color.fromRGBO(27, 38, 57, .88)
                        : const Color.fromRGBO(255, 255, 255, .88))
                  : null,
              gradient: dock
                  ? null
                  : LinearGradient(
                      begin: const Alignment(-.766, -.643),
                      end: const Alignment(.766, .643),
                      colors: [c.glass, c.glassInset],
                    ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class PressScale extends StatefulWidget {
  final Widget child;
  const PressScale({super.key, required this.child});
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool down = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => down = true),
    onPointerUp: (_) => setState(() => down = false),
    onPointerCancel: (_) => setState(() => down = false),
    child: AnimatedScale(
      scale: down ? 0.96 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: cssEase,
      child: widget.child,
    ),
  );
}

enum DgSymbol {
  dashboard,
  history,
  add,
  eye,
  eyeOff,
  sun,
  moon,
  wallet,
  edit,
  clock,
}

class DgIcon extends StatelessWidget {
  final DgSymbol symbol;
  final double size;
  final Color? color;
  const DgIcon(this.symbol, {super.key, this.size = 22, this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _IconPainter(symbol, color ?? context.palette.text),
    ),
  );
}

class _IconPainter extends CustomPainter {
  final DgSymbol symbol;
  final Color color;
  _IconPainter(this.symbol, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final p = Path();
    switch (symbol) {
      case DgSymbol.dashboard:
        for (final x in [3.0, 14.0])
          for (final y in [3.0, 14.0])
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, 7, 7),
                const Radius.circular(2),
              ),
              paint,
            );
      case DgSymbol.history:
        p.moveTo(3, 11);
        p.arcToPoint(
          const Offset(5, 18),
          radius: const Radius.circular(9),
          largeArc: true,
        );
        p.moveTo(3, 4);
        p.lineTo(3, 11);
        p.lineTo(10, 11);
        p.moveTo(12, 7);
        p.lineTo(12, 12);
        p.lineTo(15, 14);
      case DgSymbol.add:
        p.moveTo(12, 5);
        p.lineTo(12, 19);
        p.moveTo(5, 12);
        p.lineTo(19, 12);
      case DgSymbol.eye:
        p.moveTo(2, 12);
        p.cubicTo(2, 12, 5.5, 5, 12, 5);
        p.cubicTo(18.5, 5, 22, 12, 22, 12);
        p.cubicTo(22, 12, 18.5, 19, 12, 19);
        p.cubicTo(5.5, 19, 2, 12, 2, 12);
        p.close();
        canvas.drawCircle(const Offset(12, 12), 3, paint);
      case DgSymbol.eyeOff:
        p.moveTo(3, 3);
        p.lineTo(21, 21);
        p.moveTo(10.6, 5.1);
        p.lineTo(12, 5);
        p.cubicTo(18.5, 5, 22, 12, 22, 12);
        p.cubicTo(21, 13.6, 20, 15, 19, 16);
        p.moveTo(6.2, 6.2);
        p.cubicTo(4.6, 7.6, 3.2, 9.5, 2, 12);
        p.cubicTo(2, 12, 5.5, 19, 12, 19);
        p.cubicTo(14, 19, 15.8, 18.5, 17, 17.8);
        p.moveTo(10, 10);
        p.arcToPoint(
          const Offset(14, 14),
          radius: const Radius.circular(3),
          clockwise: false,
        );
      case DgSymbol.sun:
        canvas.drawCircle(const Offset(12, 12), 4, paint);
        for (final line in [
          const [12.0, 2.0, 12.0, 4.0],
          const [12.0, 20.0, 12.0, 22.0],
          const [2.0, 12.0, 4.0, 12.0],
          const [20.0, 12.0, 22.0, 12.0],
          const [5.0, 5.0, 6.5, 6.5],
          const [17.5, 17.5, 19.0, 19.0],
          const [5.0, 19.0, 6.5, 17.5],
          const [17.5, 6.5, 19.0, 5.0],
        ]) {
          p.moveTo(line[0], line[1]);
          p.lineTo(line[2], line[3]);
        }
      case DgSymbol.moon:
        p.moveTo(20.5, 13);
        p.arcToPoint(const Offset(11, 3.5), radius: const Radius.circular(9));
        p.arcToPoint(
          const Offset(20.5, 13),
          radius: const Radius.circular(9),
          largeArc: true,
          clockwise: false,
        );
        p.close();
      case DgSymbol.wallet:
        p.moveTo(20, 8);
        p.lineTo(20, 5);
        p.quadraticBezierTo(20, 3, 18, 3);
        p.lineTo(6, 3);
        p.cubicTo(2, 3, 2, 9, 6, 9);
        p.lineTo(20, 9);
        p.lineTo(20, 20);
        p.lineTo(6, 20);
        p.cubicTo(4, 20, 3, 19, 3, 17);
        p.lineTo(3, 6);
        p.moveTo(20, 12);
        p.lineTo(15, 12);
        p.lineTo(15, 17);
        p.lineTo(20, 17);
        p.moveTo(17, 14.5);
        p.lineTo(17.01, 14.5);
      case DgSymbol.edit:
        p.moveTo(16, 3);
        p.lineTo(21, 8);
        p.lineTo(9, 20);
        p.lineTo(4, 20);
        p.lineTo(4, 15);
        p.close();
        p.moveTo(13, 6);
        p.lineTo(18, 11);
      case DgSymbol.clock:
        canvas.drawCircle(const Offset(12, 12), 9, paint);
        p.moveTo(12, 6);
        p.lineTo(12, 12);
        p.lineTo(16, 14);
    }
    canvas.drawPath(p, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) =>
      oldDelegate.symbol != symbol || oldDelegate.color != color;
}

class BudgetProgress extends StatelessWidget {
  final double percent;
  final bool hidden, overBudget;
  const BudgetProgress({
    super.key,
    required this.percent,
    required this.hidden,
    required this.overBudget,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Anggaran terpakai',
    value: hidden
        ? 'Anggaran disembunyikan'
        : '${percent.round()}% anggaran terpakai',
    child: ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 5,
          color: context.palette.track,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 350),
            curve: cssEase,
            tween: Tween<double>(begin: 0, end: (percent / 100).clamp(0, 1)),
            builder: (context, v, _) => FractionallySizedBox(
              key: const Key('progress-fill'),
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: overBudget ? context.palette.expense : primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(height: 5),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<T?> showAppDialog<T>(BuildContext context, WidgetBuilder builder) =>
    Navigator.of(context).push<T>(
      _AppDialogRoute<T>(
        builder: builder,
        overlay: context.palette.dark
            ? const Color.fromRGBO(4, 6, 15, .6)
            : const Color.fromRGBO(23, 26, 48, .42),
        label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        reduced: MediaQuery.disableAnimationsOf(context),
      ),
    );

class _AppDialogRoute<T> extends PopupRoute<T> {
  final WidgetBuilder builder;
  final Color overlay;
  final String label;
  final bool reduced;
  _AppDialogRoute({
    required this.builder,
    required this.overlay,
    required this.label,
    required this.reduced,
  });
  @override
  Color get barrierColor => overlay;
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => label;
  @override
  Duration get transitionDuration =>
      reduced ? Duration.zero : const Duration(milliseconds: 300);
  @override
  Duration get reverseTransitionDuration => Duration.zero;
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => SafeArea(child: Builder(builder: builder));
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => BackdropFilter(
    filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
    child: AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = pageCurve.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - t)),
            child: Transform.scale(scale: 0.99 + .01 * t, child: child),
          ),
        );
      },
    ),
  );
}

ui.ImageFilter saturatedBlur(double blur, double saturation) {
  final s = saturation;
  return ui.ImageFilter.compose(
    outer: ui.ColorFilter.matrix([
      .213 + .787 * s,
      .715 - .715 * s,
      .072 - .072 * s,
      0,
      0,
      .213 - .213 * s,
      .715 + .285 * s,
      .072 - .072 * s,
      0,
      0,
      .213 - .213 * s,
      .715 - .715 * s,
      .072 + .928 * s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
    inner: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
  );
}
