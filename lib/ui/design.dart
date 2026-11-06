import 'package:flutter/material.dart';

const ink = Color(0xFF2C2B20);
const forest = Color(0xFF3F5F34);
const cream = Color(0xFFFBF5E5);
const terracotta = Color(0xFF975333);
const muted = Color(0xFF646653);
const line = Color(0xFFDDDCC7);
const sky = Color(0xFFD9EEF0);
const leaf = Color(0xFFAACB79);
const paleLeaf = Color(0xFFDEEBBD);
const peach = Color(0xFFF4A574);
const wood = Color(0xFFC69868);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: cream,
  fontFamily: 'Nunito',
  fontFamilyFallback: const ['KleeOne', 'ZenMaru'],
  colorScheme: ColorScheme.fromSeed(
    seedColor: forest,
    primary: forest,
    surface: cream,
    onSurface: ink,
    secondary: terracotta,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: cream,
    foregroundColor: ink,
    centerTitle: false,
    scrolledUnderElevation: 0,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: peach,
      foregroundColor: ink,
      minimumSize: Size(48, 54),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: Size(48, 48),
      side: BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFFFFEF9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: line),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  ),
);

class Paper extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  const Paper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.color = cream,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(32),
        ),
        border: Border.all(color: line.withValues(alpha: .8)),
      ),
      child: child,
    ),
  );
}

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.8,
      color: muted,
    ),
  );
}

class PageBody extends StatelessWidget {
  final Widget child;
  const PageBody({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 620),
      child: child,
    ),
  );
}

void showFailure(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Nie udało się zapisać próby. Spróbuj ponownie. ($error)'),
      duration: Duration(seconds: 8),
    ),
  );
}
