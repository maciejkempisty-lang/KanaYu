import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'design.dart';

/// Code-native decoration keeps kana and controls out of bitmap illustrations.
class LeafProgress extends StatelessWidget {
  final int value, total;
  const LeafProgress({super.key, required this.value, required this.total});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Zadanie ${value + 1} z $total',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 18,
              child: CustomPaint(painter: _Leaves(value / total)),
            ),
          ),
          const SizedBox(width: 16),
          ExcludeSemantics(
            child: Text(
              '${value + 1} z $total',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Leaves extends CustomPainter {
  final double progress;
  _Leaves(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final count = math.min(10, (size.width / 24).floor()).clamp(3, 10);
    for (var i = 0; i < count; i++) {
      final x = i * size.width / count;
      final path = Path()
        ..moveTo(x + 1, 16)
        ..quadraticBezierTo(x, 1, x + 16, 1)
        ..quadraticBezierTo(x + 15, 15, x + 1, 16);
      canvas.drawPath(
        path,
        Paint()..color = i < progress * count ? leaf : cream,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = forest
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawLine(
        Offset(x + 2, 15),
        Offset(x + 11, 6),
        Paint()
          ..color = forest
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_Leaves old) => progress != old.progress;
}

class KanaBoard extends StatelessWidget {
  final Widget child;
  const KanaBoard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 6),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: wood,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(color: Color(0xFFA8774D), offset: Offset(0, 6)),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Color(0xFFFFFEF9),
              borderRadius: BorderRadius.circular(23),
            ),
            child: child,
          ),
        ),
        Positioned.fill(
          top: -24,
          child: IgnorePointer(child: CustomPaint(painter: _Strings())),
        ),
      ],
    ),
  );
}

class _Strings extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Color(0xFF795438)
      ..strokeWidth = 3;
    for (final fraction in [.22, .78]) {
      c.drawLine(
        Offset(s.width * fraction, 0),
        Offset(s.width * fraction, 27),
        p,
      );
      c.drawCircle(Offset(s.width * fraction, 27), 4, p);
    }
  }

  @override
  bool shouldRepaint(_Strings old) => false;
}

class Meadow extends StatelessWidget {
  final Widget child;
  const Meadow({super.key, required this.child});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _Hills(),
    child: Padding(padding: const EdgeInsets.only(top: 40), child: child),
  );
}

class _Hills extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final back = Path()
      ..moveTo(0, 22)
      ..quadraticBezierTo(s.width * .25, -8, s.width * .5, 18)
      ..quadraticBezierTo(s.width * .8, 38, s.width, 10)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(back, Paint()..color = leaf);
    final front = Path()
      ..moveTo(0, 42)
      ..quadraticBezierTo(s.width * .3, 12, s.width * .55, 30)
      ..quadraticBezierTo(s.width * .8, 46, s.width, 24)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(front, Paint()..color = forest);
  }

  @override
  bool shouldRepaint(_Hills old) => false;
}

class Lantern extends StatelessWidget {
  final bool lit;
  final double size;
  const Lantern({super.key, this.lit = true, this.size = 96});
  @override
  Widget build(BuildContext context) => Semantics(
    label: lit ? 'Zapalony lampion' : 'Lampion przy szkole',
    child: SizedBox(
      width: size,
      height: size * 1.3,
      child: CustomPaint(painter: _Lantern(lit)),
    ),
  );
}

class _Lantern extends CustomPainter {
  final bool lit;
  _Lantern(this.lit);
  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 100, s.height / 130);
    if (lit) {
      c.drawCircle(
        Offset(50, 65),
        40,
        Paint()
          ..color = Color(0x88FFD983)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    final p = Paint()
      ..color = forest
      ..strokeWidth = 2;
    c.drawLine(Offset(50, 0), Offset(50, 22), p);
    final rect = Rect.fromLTRB(20, 22, 80, 104);
    c.drawOval(rect, Paint()..color = lit ? Color(0xFFFFDB8F) : cream);
    c.drawOval(
      rect,
      Paint()
        ..color = wood
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final y in [40.0, 55.0, 70.0, 85.0]) {
      c.drawLine(
        Offset(23, y),
        Offset(77, y),
        Paint()
          ..color = wood.withValues(alpha: .6)
          ..strokeWidth = 1,
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(39, 19, 61, 25),
        Radius.circular(2),
      ),
      p,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(39, 101, 61, 107),
        Radius.circular(2),
      ),
      p,
    );
    c.drawLine(Offset(50, 107), Offset(50, 127), p);
  }

  @override
  bool shouldRepaint(_Lantern old) => lit != old.lit;
}
