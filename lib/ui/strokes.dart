import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'design.dart';

typedef Drawing = List<List<List<num>>>;

class StrokeView extends StatefulWidget {
  final List<String> paths;
  final Drawing drawing;
  final bool animate, overlay;
  final double size;
  const StrokeView({
    super.key,
    this.paths = const [],
    this.drawing = const [],
    this.animate = false,
    this.overlay = false,
    this.size = 210,
  });
  @override
  State<StrokeView> createState() => _StrokeViewState();
}

class _StrokeViewState extends State<StrokeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: Duration(seconds: 5),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(StrokeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.animate && !MediaQuery.disableAnimationsOf(context)) {
      if (!animation.isAnimating) animation.repeat();
    } else {
      animation.stop();
      animation.value = 1;
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: AnimatedBuilder(
      animation: animation,
      builder: (_, _) => CustomPaint(
        painter: KanaPainter(
          paths: widget.paths,
          drawing: widget.drawing,
          progress: widget.animate ? (animation.value * 1.3).clamp(0, 1) : 1,
          overlay: widget.overlay,
        ),
      ),
    ),
  );
}

class KanaPainter extends CustomPainter {
  final List<String> paths;
  final Drawing drawing;
  final double progress;
  final bool overlay;
  KanaPainter({
    this.paths = const [],
    this.drawing = const [],
    this.progress = 1,
    this.overlay = false,
  });
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(18)),
      Paint()..color = cream,
    );
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, 10),
      Offset(size.width / 2, size.height - 10),
      grid,
    );
    canvas.drawLine(
      Offset(10, size.height / 2),
      Offset(size.width - 10, size.height / 2),
      grid,
    );
    canvas.save();
    canvas.scale(size.width / 109, size.height / 109);
    final p = Paint()
      ..color = (overlay ? terracotta.withValues(alpha: .32) : forest)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < paths.length; i++) {
      final amount = (progress * paths.length - i).clamp(0.0, 1.0);
      if (amount == 0) continue;
      for (final metric in parseSvgPathData(paths[i]).computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * amount), p);
      }
    }
    p.color = ink;
    p.strokeWidth = 2.6;
    final total = drawing.fold<int>(0, (n, s) => n + s.length);
    var remaining = (total * progress).ceil();
    for (final stroke in drawing) {
      final n = math.min(stroke.length, remaining);
      remaining -= n;
      if (n == 0) continue;
      final path = Path()
        ..moveTo(
          stroke.first[0].toDouble() * 109,
          stroke.first[1].toDouble() * 109,
        );
      for (final point in stroke.take(n).skip(1)) {
        path.lineTo(point[0].toDouble() * 109, point[1].toDouble() * 109);
      }
      if (n == 1) {
        canvas.drawCircle(
          Offset(
            stroke.first[0].toDouble() * 109,
            stroke.first[1].toDouble() * 109,
          ),
          1.3,
          p..style = PaintingStyle.fill,
        );
        p.style = PaintingStyle.stroke;
      } else {
        canvas.drawPath(path, p);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(KanaPainter oldDelegate) => true;
}

class DrawingPad extends StatefulWidget {
  final Drawing drawing;
  final VoidCallback onChanged;
  const DrawingPad({super.key, required this.drawing, required this.onChanged});
  @override
  State<DrawingPad> createState() => _DrawingPadState();
}

class _DrawingPadState extends State<DrawingPad> {
  final stopwatch = Stopwatch()..start();
  int? pointer;
  void point(Offset position, Size size) => widget.drawing.last.add([
    (position.dx / size.width).clamp(0, 1),
    (position.dy / size.height).clamp(0, 1),
    stopwatch.elapsedMilliseconds,
  ]);
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pole do pisania znaku palcem lub rysikiem',
    child: LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        // Claim the gesture so the surrounding lesson does not scroll while writing.
        onPanStart: (_) {},
        onPanUpdate: (_) {},
        child: Listener(
          onPointerDown: (e) {
            if (pointer != null) return;
            pointer = e.pointer;
            widget.drawing.add([]);
            point(e.localPosition, constraints.biggest);
            setState(() {});
            widget.onChanged();
          },
          onPointerMove: (e) {
            if (e.pointer != pointer) return;
            point(e.localPosition, constraints.biggest);
            setState(() {});
          },
          onPointerUp: (e) {
            if (e.pointer == pointer) pointer = null;
          },
          onPointerCancel: (e) {
            if (e.pointer == pointer) pointer = null;
          },
          child: CustomPaint(
            painter: KanaPainter(drawing: widget.drawing),
            size: Size.infinite,
          ),
        ),
      ),
    ),
  );
}
