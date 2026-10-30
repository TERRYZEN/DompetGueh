import 'package:flutter/material.dart';

const primary = Color(0xff038df7);
const green = Color(0xff1caa7b);
const orange = Color(0xfff59a45);

class Palette {
  final bool dark;
  const Palette(this.dark);
  Color get bg => dark ? const Color(0xff0e1120) : const Color(0xfff6f7fb);
  Color get surface => dark ? const Color(0xff171b2e) : Colors.white;
  Color get text => dark ? const Color(0xffe9ecf7) : const Color(0xff20243a);
  Color get muted => dark ? const Color(0xff98a0b8) : const Color(0xff8a90a5);
  Color get line => dark ? const Color(0xff262b44) : const Color(0xffedf0f6);
  Color get soft => dark ? const Color(0xff232a4d) : const Color(0xffefedff);
  Color get field => dark ? const Color(0xff12162a) : Colors.white;
}

extension UiContext on BuildContext {
  Palette get palette => Palette(Theme.of(this).brightness == Brightness.dark);
}

TextStyle heading(double size, {Color? color}) => TextStyle(
  fontFamily: 'Manrope',
  fontSize: size,
  fontWeight: FontWeight.w800,
  letterSpacing: -.7,
  color: color,
);

ThemeData appTheme(bool dark) {
  final c = Palette(dark);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c.line),
  );
  return ThemeData(
    useMaterial3: false,
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: 'DMSans',
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(primary: primary, surface: c.surface),
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontSize: 14, color: c.text),
      bodySmall: TextStyle(fontSize: 12, color: c.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.field,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xffdf5967)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      hintStyle: TextStyle(fontSize: 14, color: c.muted),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: primary),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: primary,
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: c.text,
        backgroundColor: c.surface,
        minimumSize: const Size(0, 42),
        side: BorderSide(color: c.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.text,
      contentTextStyle: TextStyle(
        fontFamily: 'DMSans',
        color: c.surface,
        fontSize: 12,
      ),
    ),
  );
}
