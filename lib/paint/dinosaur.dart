import 'package:dinosaur_run/paint/portrayal.dart';
import 'package:flutter/material.dart';

///恐龙
class Dinosaur extends CustomPainter {
  Paint _paint;
  Color color;
  DinosaurState state;

  Map<DinosaurState, List<List<int>>> maps = {
    DinosaurState.STAND: Portrayal.stand_map,
    DinosaurState.RUN_1: Portrayal.run1_map,
    DinosaurState.RUN_2: Portrayal.run2_map,
    DinosaurState.DIE: Portrayal.die_map
  };

  Dinosaur(
      {this.color = const Color(0xff808080), this.state = DinosaurState.STAND});

  @override
  void paint(Canvas canvas, Size size) {
    if (_paint == null) {
      initPaint();
    }
    _paint.color = color;

    double y = 0;
    maps[state]?.map((line) {
      line.asMap().forEach((index, unit) {
        if (unit == 1) {
          double x = (index + 1) * Portrayal.pixelUnit;
          drawPixel(canvas, Offset(x, y));
        }
      });

      y += Portrayal.pixelUnit;
    }).toList();
  }

  void drawPixel(Canvas canvas, Offset coord) {
    canvas.drawRect(
        Rect.fromLTWH(
            coord.dx, coord.dy, Portrayal.pixelUnit, Portrayal.pixelUnit),
        _paint);
  }

  void initPaint() {
    _paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
  }

  static Size getWrapSize() {
    return Size(Portrayal.stand_map[0].length * Portrayal.pixelUnit,
        Portrayal.stand_map.length * Portrayal.pixelUnit);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return (oldDelegate as Dinosaur).state != state ||
        (oldDelegate as Dinosaur).color != color;
  }
}
