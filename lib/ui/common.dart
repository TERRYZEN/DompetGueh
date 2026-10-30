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
        borderRadius: BorderRadius.circular(16),
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
  const FormLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
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
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: Color(0xffa0a5b7),
    ),
  );
}

class Brand extends StatelessWidget {
  final bool large;
  const Brand({super.key, this.large = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: large ? 52 : 32,
        height: large ? 52 : 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(large ? 16 : 12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: large
                ? const [primary, Color(0xff2f00ff)]
                : const [Color(0xff0004f4), Color(0xff037ff4)],
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: .16),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text('D', style: heading(large ? 26 : 20, color: Colors.white)),
      ),
      if (!large) ...[
        const SizedBox(width: 11),
        Text.rich(
          TextSpan(
            style: heading(20),
            children: const [
              TextSpan(text: 'Dompet'),
              TextSpan(
                text: 'Gueh',
                style: TextStyle(color: primary),
              ),
            ],
          ),
        ),
      ],
    ],
  );
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
