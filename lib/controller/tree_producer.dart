import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:dinosaur_run/controller/location.dart';
import 'package:dinosaur_run/paint/portrayal.dart';
import 'package:dinosaur_run/paint/tree.dart';

///树 生产工厂
class TreeProducer {
  List<TreeLocation> treeLists = [];

  ///最小初始x值，应当等于刚刚在右侧控件外的值（即控件宽度）
  double minBaseX;
  double baseY;
  math.Random _random;

  TreeProducer(this.minBaseX, this.baseY);

  void tryProductTrees() {
    _random ??= math.Random();
    //当列表中最后一个树的位置都已经移动到控件内时，那么要在右侧控件外重新生产出一组树加入到列表。
    bool needProduct = treeLists.length == 0 || treeLists.last.x < minBaseX;

    if (needProduct) {
      //每次生产10组树
      double x = minBaseX;
      for (int i = 0; i < 10; i++) {
        //每组树间距[250,500]
        x += Portrayal.pixelUnit * 250 +
            _random.nextInt((Portrayal.pixelUnit * 250).toInt());

        int a = _random.nextInt(5);
        switch (a) {
          case 0:
            addTree1(x);
            break;
          case 1:
            addTree2(x);
            break;
          case 2:
            addTree3(x);
            break;
          case 3:
            addTree4(x);
            break;
          case 4:
            addTree5(x);
            break;
        }
      }
    }
  }


  void addTree1(double baseX) {
    TreeLocation location = TreeLocation(
        TreeType.TYPE_3,
        Tree.getWrapSize(TreeType.TYPE_3),
        baseX,
        baseY - Tree.getWrapSize(TreeType.TYPE_3).height);
    treeLists.add(location);
  }

  void addTree2(double baseX) {
    TreeLocation location = TreeLocation(
        TreeType.TYPE_1,
        Tree.getWrapSize(TreeType.TYPE_1),
        baseX,
        baseY - Tree.getWrapSize(TreeType.TYPE_1).height);
    treeLists.add(location);
  }

  void addTree3(double baseX) {
    TreeLocation location = TreeLocation(
        TreeType.TYPE_1,
        Tree.getWrapSize(TreeType.TYPE_1),
        baseX,
        baseY - Tree.getWrapSize(TreeType.TYPE_1).height);
    TreeLocation location2 = TreeLocation(
        TreeType.TYPE_2,
        Tree.getWrapSize(TreeType.TYPE_2),
        location.x +
            Tree.getWrapSize(TreeType.TYPE_1).width +
            Portrayal.pixelUnit,
        baseY - Tree.getWrapSize(TreeType.TYPE_2).height);
    treeLists.add(location);
    treeLists.add(location2);
  }

  void addTree4(double baseX) {
    TreeLocation location = TreeLocation(
        TreeType.TYPE_1,
        Tree.getWrapSize(TreeType.TYPE_1),
        baseX,
        baseY - Tree.getWrapSize(TreeType.TYPE_1).height);

    TreeLocation location2 = TreeLocation(
        TreeType.TYPE_3,
        Tree.getWrapSize(TreeType.TYPE_3),
        location.x +
            Tree.getWrapSize(TreeType.TYPE_1).width +
            Portrayal.pixelUnit,
        baseY - Tree.getWrapSize(TreeType.TYPE_3).height);

    TreeLocation location3 = TreeLocation(
        TreeType.TYPE_2,
        Tree.getWrapSize(TreeType.TYPE_2),
        location2.x + Tree.getWrapSize(TreeType.TYPE_3).width,
        baseY - Tree.getWrapSize(TreeType.TYPE_2).height);

    treeLists.add(location);
    treeLists.add(location2);
    treeLists.add(location3);
  }

  void addTree5(double baseX) {
    TreeLocation location = TreeLocation(
        TreeType.TYPE_1,
        Tree.getWrapSize(TreeType.TYPE_1),
        baseX,
        baseY - Tree.getWrapSize(TreeType.TYPE_1).height);

    TreeLocation location2 = TreeLocation(
        TreeType.TYPE_3,
        Tree.getWrapSize(TreeType.TYPE_3),
        location.x +
            Tree.getWrapSize(TreeType.TYPE_1).width +
            Portrayal.pixelUnit,
        baseY - Tree.getWrapSize(TreeType.TYPE_3).height);

    TreeLocation location3 = TreeLocation(
        TreeType.TYPE_2,
        Tree.getWrapSize(TreeType.TYPE_2),
        location2.x +
            Tree.getWrapSize(TreeType.TYPE_3).width +
            Portrayal.pixelUnit,
        baseY - Tree.getWrapSize(TreeType.TYPE_2).height);

    TreeLocation location4 = TreeLocation(
        TreeType.TYPE_1,
        Tree.getWrapSize(TreeType.TYPE_1),
        location3.x + Tree.getWrapSize(TreeType.TYPE_2).width,
        baseY - Tree.getWrapSize(TreeType.TYPE_1).height);

    treeLists.add(location);
    treeLists.add(location2);
    treeLists.add(location3);
    treeLists.add(location4);
  }
}

class TreeLocation extends Location {
  TreeType treeType;

  TreeLocation(this.treeType, Size size, double x, double y)
      : super(size, x, y);
}
