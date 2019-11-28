import 'package:dinosaur_run/paint/portrayal.dart';
import 'package:flutter/material.dart';

///云朵
class Cloud extends CustomPainter {
  Paint _paint;
  Color color;

  Cloud({this.color = const Color.fromARGB(255, 200, 200, 200)});

  @override
  void paint(Canvas canvas, Size size) {
    if (_paint == null) {
      initPaint();
    }
    _paint.color = color;

    double y = 0;
    Portrayal.cloud_map.map((line) {
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
    return Size(Portrayal.cloud_map[0].length * Portrayal.pixelUnit,
        Portrayal.cloud_map.length * Portrayal.pixelUnit);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    ///云朵外观不会因外部变化而变化
    return false;
  }
}
