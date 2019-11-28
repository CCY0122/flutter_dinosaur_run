import 'package:dinosaur_run/paint/portrayal.dart';
import 'package:flutter/material.dart';

///树
class Tree extends CustomPainter {
  Paint _paint;
  Color color;
  TreeType type;

  static const Map<TreeType, List<List<int>>> maps = {
    TreeType.TYPE_1: Portrayal.tree1_map,
    TreeType.TYPE_2: Portrayal.tree2_map,
    TreeType.TYPE_3: Portrayal.tree3_map,
  };

  Tree({this.color = const Color(0xff808080), this.type = TreeType.TYPE_1});

  @override
  void paint(Canvas canvas, Size size) {
    if (_paint == null) {
      initPaint();
    }
    _paint.color = color;

    double y = 0;
    maps[type]?.map((line) {
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

  static Size getWrapSize(TreeType type) {
    return Size(maps[type][0].length * Portrayal.pixelUnit,
        maps[type].length * Portrayal.pixelUnit);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return (oldDelegate as Tree).type != type ||
        (oldDelegate as Tree).color != color;
  }
}
