import 'dart:async';
import 'dart:ui' as ui;

import 'package:dinosaur_run/controller/location.dart';
import 'package:dinosaur_run/controller/tree_producer.dart';
import 'package:dinosaur_run/paint/cloud.dart';
import 'package:dinosaur_run/paint/dinosaur.dart';
import 'package:dinosaur_run/paint/portrayal.dart';
import 'package:dinosaur_run/paint/tree.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

///动画状态
enum GameState {
  ///初始状态
  INIT,

  ///游戏中
  PLAYING,

  ///游戏结束
  GAMEOVER,
}

class DinosaurRunLayout extends StatefulWidget {
  @override
  _DinosaurRunLayoutState createState() => _DinosaurRunLayoutState();
}

class _DinosaurRunLayoutState extends State<DinosaurRunLayout>
    with TickerProviderStateMixin {
  double _layoutWidth;
  Color primaryColor = Color(0xff808080);
  Color tingeColor = Color.fromARGB(255, 200, 200, 200);

  ///游戏状态
  GameState _gameState;

  ///移动速度。体现于每一动画帧移动距离
  int _moveVelocityPerFrame = 2;
  int _maxMoveVelocityPerFrame = 8;

  ///物体移动动画
  AnimationController _moveAnim;

  ///恐龙跑步动画
  AnimationController _dinosaurRunAnim;
  DinosaurState _dinosaurState;

  ///恐龙跳跃动画
  AnimationController _dinosaurJumpAnimCtrl;
  Animation _dinosaurJumpAnim;
  

  ///分数、难度控制器
  Timer _levelTimer;

  ///恐龙当前位置信息
  Location dinosaurLocation;

  ///树 生产工厂
  TreeProducer treeProducer;

  ///云朵位置列表
  List<Location> cloudList;
  
  

  //todo 构造函数

  @override
  void initState() {
    super.initState();
    MediaQueryData mediaQuery = MediaQueryData.fromWindow(ui.window);
    _layoutWidth = mediaQuery.size.width; //默认宽度为屏幕宽

    treeProducer = TreeProducer(_layoutWidth, 140);
    initAnim();
  }

  void initAnim() {
    _moveAnim = AnimationController(
        vsync: this, duration: Duration(seconds: 20));
    _moveAnim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _moveAnim.forward(from: _moveAnim.lowerBound);
      }
    });

    _dinosaurRunAnim =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    _dinosaurRunAnim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_dinosaurJumpAnimCtrl.isAnimating) {
          _dinosaurState = DinosaurState.STAND;
        } else {
          if (_dinosaurState == DinosaurState.RUN_1) {
            _dinosaurState = DinosaurState.RUN_2;
          } else {
            _dinosaurState = DinosaurState.RUN_1;
          }
        }
        _dinosaurRunAnim.forward(from: _dinosaurRunAnim.lowerBound);
      }
    });

    _dinosaurJumpAnimCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 350));
    _dinosaurJumpAnim = Tween<double>(begin: 0, end: 85 * Portrayal.pixelUnit)
        .animate(CurvedAnimation(
            parent: _dinosaurJumpAnimCtrl, curve: Curves.decelerate));
    _dinosaurJumpAnim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dinosaurJumpAnimCtrl.reverse();
      }
    });
  }

  ///云朵布局
  Widget getClouds() {
    cloudList ??= [
      Location(Cloud.getWrapSize(), _layoutWidth / 3, 10),
      Location(Cloud.getWrapSize(), _layoutWidth * 2 / 3, 30),
      Location(Cloud.getWrapSize(), _layoutWidth, 20),
    ];
    return AnimatedBuilder(
      animation: _moveAnim,
      builder: (context, _) {
        cloudList.map((location) {
          updateCloudOffsetByAnim(
              _layoutWidth + Cloud.getWrapSize().width, location);
        }).toList();
        return Stack(
          children: cloudList.map((location) {
            return Positioned(
              left: location.x,
              top: location.y,
              child: CustomPaint(
                painter: Cloud(),
                size: Cloud.getWrapSize(),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  ///计算云朵所处位置的偏移量。云朵是从右向左移动，当向左移出屏幕时，要重新从右侧移入
  void updateCloudOffsetByAnim(double totalDelta, Location location) {
    location.x -= _moveVelocityPerFrame;

    //云朵移出了左屏幕，从右侧重新移入
    while (location.x < -Cloud.getWrapSize().width) {
      location.x += totalDelta;
    }
  }

  ///恐龙布局
  Widget getDinosaur() {
    double baseTopMargin = 140 - Dinosaur.getWrapSize().height;
    dinosaurLocation ??= Location(Dinosaur.getWrapSize(), 10, baseTopMargin);

    return AnimatedBuilder(
      animation: _dinosaurJumpAnim,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: _dinosaurRunAnim,
          builder: (context, _) {
            dinosaurLocation.y = baseTopMargin - _dinosaurJumpAnim.value;
            return Stack(
              children: <Widget>[
                Positioned(
                  top: dinosaurLocation.y,
                  left: dinosaurLocation.x,
                  child: CustomPaint(
                    painter:
                        Dinosaur(state: _dinosaurState ?? DinosaurState.STAND),
                    size: Dinosaur.getWrapSize(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  ///树布局
  Widget getTrees() {
    return AnimatedBuilder(
      animation: _moveAnim,
      builder: (context, _) {
        List<TreeLocation> treeListsCopy = treeProducer.treeLists.toList();
        //遍历中涉及元素移除，使用copy进行遍历
        treeListsCopy.map((location) {
          updateTreeOffsetByAnim(location);
        }).toList();

        return Stack(
          children: treeProducer.treeLists.map((location) {
            return Positioned(
              left: location.x,
              top: location.y,
              child: CustomPaint(
                painter: Tree(type: location.treeType),
                size: Tree.getWrapSize(location.treeType),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  ///更新树所处位置的偏移量。树是从右向左移动，当向左移出屏幕时，要从队列里移除
  void updateTreeOffsetByAnim(TreeLocation location) {
    location.x -= _moveVelocityPerFrame;

    //树移出了左屏幕，从队列里移除
    if (location.x < -Tree.getWrapSize(location.treeType).width) {
      treeProducer.treeLists.remove(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: Stack(
        children: <Widget>[
          //云朵
          getClouds(),
          //地面
          Positioned(
            top: 130,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 1,
              color: primaryColor,
            ),
          ),
          //恐龙
          getDinosaur(),
          //树
          getTrees(),
        ],
      ),
    );
  }

  ///fixme
  void tap() {
    switch (_gameState) {
      case GameState.PLAYING:
        break;
      case GameState.GAMEOVER:
        break;
      case GameState.INIT:
        break;
    }
    if (_moveAnim.isAnimating) {
//      _levelTimer.cancel();
//      _level = 1;
//      _cloudAnim.stop();
    } else {
      _moveAnim.forward();
      _levelTimer = Timer.periodic(Duration(seconds: 10), (timer) {
        print('tick');
        _moveVelocityPerFrame = math.min(_maxMoveVelocityPerFrame, ++_moveVelocityPerFrame);
      });
      treeProducer.productTrees();
    }

    if (_dinosaurRunAnim.isAnimating) {
//      _dinosaurRunAnim.stop();
    } else {
      _dinosaurRunAnim.forward();
    }

    if (_dinosaurJumpAnimCtrl.isAnimating) {
    } else {
      _dinosaurJumpAnimCtrl.forward();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _levelTimer?.cancel();
  }
}
