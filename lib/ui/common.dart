import 'package:flutter/material.dart';
import 'theme.dart';

void toast(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 3),
      backgroundColor: error ? const Color(0xffc43c4b) : null,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 98),
    ),
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  });
  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .12 : .025),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FormLabel extends StatelessWidget {
  final String text;
  final double size;
  const FormLabel(this.text, {super.key, this.size = 11});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: context.palette.dark
            ? const Color(0xffaab1c7)
            : const Color(0xff555b71),
      ),
    ),
  );
}

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: context.palette.muted,
    ),
  );
}

class Brand extends StatelessWidget {
  final bool large;
  const Brand({super.key, this.large = false});
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width <= 760;
    final size = large
        ? 52.0
        : mobile
        ? 32.0
        : 37.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              large
                  ? 16
                  : mobile
                  ? 10
                  : 12,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: .15),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              large
                  ? 16
                  : mobile
                  ? 10
                  : 12,
            ),
            child: Image.asset(
              'assets/images/logo.jpeg',
              key: const Key('dg-logo'),
              width: size,
              height: size,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
        ),
        if (!large) ...[
          SizedBox(width: mobile ? 8 : 10),
          Text.rich(
            TextSpan(
              style: heading(
                width < 360
                    ? 17
                    : mobile
                    ? 19
                    : 22,
              ),
              children: [
                const TextSpan(text: 'Dompet'),
                TextSpan(
                  text: 'Gueh',
                  style: TextStyle(
                    color: context.palette.dark
                        ? const Color(0xff4da9ff)
                        : primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class SmallIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const SmallIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        child: Icon(icon, size: 19, semanticLabel: label),
      ),
    ),
  );
}
