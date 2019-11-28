import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dinosaur_run/controller/location.dart';
import 'package:dinosaur_run/paint/cloud.dart';
import 'package:dinosaur_run/paint/dinosaur.dart';
import 'package:dinosaur_run/paint/portrayal.dart';
import 'package:flutter/material.dart';

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

  ///难度等级。体现在动画速度上
  int _level = 0;
  int _maxLevel = 6;

  ///云朵移动动画
  AnimationController _cloudAnim;

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

  //todo 构造函数

  @override
  void initState() {
    super.initState();
    MediaQueryData mediaQuery = MediaQueryData.fromWindow(ui.window);
    _layoutWidth = mediaQuery.size.width; //默认宽度为屏幕宽

    initAnim();
  }

  void initAnim() {
    _cloudAnim = AnimationController(
        vsync: this, duration: getMoveDurationByLevel(_level));
    _cloudAnim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (getMoveDurationByLevel(_level) != _cloudAnim.duration) {
          _cloudAnim.duration = getMoveDurationByLevel(_level);
        }
        _cloudAnim.forward(from: _cloudAnim.lowerBound);
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
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _dinosaurJumpAnim = Tween<double>(begin: 0, end: 80 * Portrayal.pixelUnit)
        .animate(CurvedAnimation(
            parent: _dinosaurJumpAnimCtrl, curve: Curves.decelerate));
    _dinosaurJumpAnim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dinosaurJumpAnimCtrl.reverse();
      }
    });
  }

  ///根据当前难度计算出动画移动速度
  Duration getMoveDurationByLevel(int level) {
    //7 level : 4s -> 3.5 -> ,,, -> 1.5 -> 1s
    int delta = 500;
    return Duration(milliseconds: 4000 - delta * level);
  }

  ///云朵布局
  Widget getClouds() {
    return AnimatedBuilder(
      animation: _cloudAnim,
      builder: (context, _) {
        return Stack(
          children: <Widget>[
            Positioned(
              left: calculateCloudOffsetByAnim(_cloudAnim,
                  _layoutWidth + Cloud.getWrapSize().width, _layoutWidth / 3),
              top: 10,
              child: CustomPaint(
                painter: Cloud(),
                size: Cloud.getWrapSize(),
              ),
            ),
            Positioned(
              left: calculateCloudOffsetByAnim(
                  _cloudAnim,
                  _layoutWidth + Cloud.getWrapSize().width,
                  _layoutWidth * 2 / 3),
              top: 30,
              child: CustomPaint(
                painter: Cloud(),
                size: Cloud.getWrapSize(),
              ),
            ),
            Positioned(
              left: calculateCloudOffsetByAnim(_cloudAnim,
                  _layoutWidth + Cloud.getWrapSize().width, _layoutWidth),
              top: 20,
              child: CustomPaint(
                painter: Cloud(),
                size: Cloud.getWrapSize(),
              ),
            ),
          ],
        );
      },
    );
  }

  ///计算云朵所处位置的偏移量。云朵是从右向左移动，当向左移出屏幕时，要重新从右侧移入
  double calculateCloudOffsetByAnim(
      Animation animation, double totalDelta, double beginOffset) {
    double result = beginOffset - (totalDelta * animation.value);

    //云朵移出了左屏幕，从右侧重新移入
    while (result < -Cloud.getWrapSize().width) {
      result += totalDelta;
    }
    return result;
  }

  ///恐龙布局
  Widget getDinosaur() {
    double baseTopMargin = 130 - Dinosaur.getWrapSize().height * 0.8;
    dinosaurLocation ??=
        Location(Dinosaur.getWrapSize(), Offset(10, baseTopMargin));

    return AnimatedBuilder(
      animation: _dinosaurJumpAnim,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: _dinosaurRunAnim,
          builder: (context, _) {
            dinosaurLocation.coordinate =
                Offset(10, baseTopMargin - _dinosaurJumpAnim.value);
            return Stack(
              children: <Widget>[
                Positioned(
                  top: dinosaurLocation.coordinate.dy,
                  left: dinosaurLocation.coordinate.dx,
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
    if (_cloudAnim.isAnimating) {
//      _levelTimer.cancel();
//      _level = 1;
//      _cloudAnim.stop();
    } else {
      _cloudAnim.forward();
      _levelTimer = Timer.periodic(Duration(seconds: 10), (timer) {
        print('timer ,level = $_level , tick = ${timer.tick}');
        _level = math.min(++_level, _maxLevel);
      });
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
