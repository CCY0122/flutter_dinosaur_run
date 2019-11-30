import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dinosaur_run/controller/location.dart';
import 'package:dinosaur_run/controller/tree_producer.dart';
import 'package:dinosaur_run/paint/cloud.dart';
import 'package:dinosaur_run/paint/dinosaur.dart';
import 'package:dinosaur_run/paint/portrayal.dart';
import 'package:dinosaur_run/paint/tree.dart';
import 'package:flutter/material.dart';

typedef GameStatusListener = void Function(GameState status, int maxScore);

///动画状态
enum GameState {
  ///初始状态
  INIT,

  ///游戏中
  PLAYING,

  ///游戏结束
  GAMEOVER,
}

class DinosaurRun extends StatefulWidget {
  GameStatusListener gameStatusListener;

  DinosaurRun({Key key, this.gameStatusListener}) : super(key: key);

  @override
  _DinosaurRunState createState() => _DinosaurRunState();
}

class _DinosaurRunState extends State<DinosaurRun>
    with TickerProviderStateMixin {
  double _layoutWidth;
  Color primaryColor = Color(0xff808080);
  Color tingeColor = Color.fromARGB(255, 200, 200, 200);

  ///游戏状态
  GameState _gameState = GameState.INIT;

  ///移动速度。体现于每一动画帧移动距离
  int _moveVelocityPerFrame = 3;
  int _maxMoveVelocityPerFrame = 10;

  ///物体移动动画
  AnimationController _moveAnim;
  int lastMoveAnimUpdateTime;

  ///恐龙跑步动画
  AnimationController _dinosaurRunAnim;
  DinosaurState _dinosaurState;

  ///恐龙跳跃动画
  AnimationController _dinosaurJumpAnimCtrl;
  Animation _dinosaurJumpAnim;

  ///难度控制器
  Timer _levelTimer;

  ///恐龙当前位置信息
  Location dinosaurLocation;

  ///树 生产工厂
  TreeProducer treeProducer;

  ///云朵位置列表
  List<Location> cloudList;

  ///分数
  int score = 0;
  int maxScore = 0;

  @override
  void initState() {
    super.initState();
    MediaQueryData mediaQuery = MediaQueryData.fromWindow(ui.window);
    _layoutWidth = mediaQuery.size.width; //默认宽度为屏幕宽

    treeProducer = TreeProducer(_layoutWidth, 140);
    cloudList ??= [
      Location(Cloud.getWrapSize(), _layoutWidth / 3, 10),
      Location(Cloud.getWrapSize(), _layoutWidth * 2 / 3, 30),
      Location(Cloud.getWrapSize(), _layoutWidth, 20),
    ];
    initAnim();
  }

  void initAnim() {
    _moveAnim = AnimationController(vsync: this, duration: Duration(days: 1));
    _moveAnim.addListener(() {
      //因为动画每次回调间隔不明确，因此手动计算每次回调间隔帧数,然后换算出物体应当移动的距离
      //问：为什么不用Timer.periodic()实现每16.6ms回调一次更新动画的做法呢？
      //答：实测Timer回调间隔波动大（release版也一样,不知为何），动画肉眼可见的不匀速
      if (lastMoveAnimUpdateTime == null) {
        lastMoveAnimUpdateTime = DateTime.now().millisecondsSinceEpoch;
        return;
      }
      //计算间隔了多少帧（16.6ms）
      int nowTime = DateTime.now().millisecondsSinceEpoch;
      double hasPassedFrameCount =
          (nowTime - lastMoveAnimUpdateTime) / (1000 / 60);
      lastMoveAnimUpdateTime = nowTime;
//      print('hasPassedFrameCount = $hasPassedFrameCount'); //约1~3帧
      moveTimerTick(hasPassedFrameCount);
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
    _dinosaurJumpAnim = Tween<double>(begin: 0, end: 85 * Portrayal.pixelUnit)
        .animate(CurvedAnimation(
            parent: _dinosaurJumpAnimCtrl, curve: Curves.decelerate));
    _dinosaurJumpAnim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dinosaurJumpAnimCtrl.reverse();
      }
    });
  }

  moveTimerTick(double hasPassedFrameCount) {
    score++; //简单点，每次回调就+1分
    maxScore = max(score, maxScore);

    cloudList.map((location) {
      updateCloudOffsetByAnim(hasPassedFrameCount,
          _layoutWidth + Cloud.getWrapSize().width, location);
    }).toList();

    List<TreeLocation> treeListsCopy = treeProducer.treeLists.toList();
    //遍历中涉及元素移除，使用copy进行遍历
    treeListsCopy.map((location) {
      updateTreeOffsetByAnim(hasPassedFrameCount, location);
    }).toList();

    treeProducer.tryProductTrees();

    if (isDie()) {
      stop();
      _dinosaurState = DinosaurState.DIE;
      _gameState = GameState.GAMEOVER;
      widget.gameStatusListener?.call(_gameState, maxScore);
    }
    if (mounted) {
      setState(() {});
    }
  }

  ///计算云朵所处位置的偏移量。云朵是从右向左移动，当向左移出屏幕时，要重新从右侧移入
  void updateCloudOffsetByAnim(
      double hasPassedFrameCount, double totalDelta, Location location) {
    location.x -= _moveVelocityPerFrame * hasPassedFrameCount;

    //云朵移出了左屏幕，从右侧重新移入
    while (location.x < -Cloud.getWrapSize().width) {
      location.x += totalDelta;
    }
  }

  ///更新树所处位置的偏移量。树是从右向左移动，当向左移出屏幕时，要从队列里移除
  void updateTreeOffsetByAnim(
      double hasPassedFrameCount, TreeLocation location) {
    location.x -= _moveVelocityPerFrame * hasPassedFrameCount;

    //树移出了左屏幕，从队列里移除
    if (location.x < -Tree.getWrapSize(location.treeType).width) {
      treeProducer.treeLists.remove(location);
    }
  }

  bool isDie() {
    bool isDie = false;
    treeProducer.treeLists.map((treeLocation) {
      if (treeLocation.x <
              dinosaurLocation.x +
                  dinosaurLocation.size.width -
                  5 * Portrayal.pixelUnit /*放宽5个单位横向重叠区域*/
          &&
          treeLocation.x + treeLocation.size.width >
              dinosaurLocation.x + 5 * Portrayal.pixelUnit /*放宽5个单位横向重叠区域*/
          &&
          treeLocation.y <
              dinosaurLocation.y +
                  dinosaurLocation.size.height -
                  10 * Portrayal.pixelUnit /*放宽10个单位纵向区域*/) {
        isDie = true;
        return;
      }
    }).toList();

    return isDie;
  }

  ///云朵布局
  Widget getClouds() {
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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: tap,
      child: Container(
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            //云朵
            getClouds(),
            //地面
            Positioned(
              top: 135,
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
            //分数
            Positioned(
              right: 0,
              top: 0,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  '$score / $maxScore',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ),
            Offstage(
              offstage: _gameState != GameState.GAMEOVER,
              child: Text(
                'Game Over',
                style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            )
          ],
        ),
      ),
    );
  }

  void tap(TapDownDetails details) {
    switch (_gameState) {
      case GameState.INIT:
        reset();
        _levelTimer = Timer.periodic(Duration(seconds: 15), (timer) {
          _moveVelocityPerFrame =
              min(++_moveVelocityPerFrame, _maxMoveVelocityPerFrame);
        });
        _dinosaurRunAnim.forward();
        _dinosaurJumpAnimCtrl.forward();
        _moveAnim.forward();
        _gameState = GameState.PLAYING;
        widget.gameStatusListener?.call(_gameState, maxScore);
        break;
      case GameState.PLAYING:
        if (_dinosaurJumpAnimCtrl.isAnimating) {
          return;
        }
        _dinosaurJumpAnimCtrl.forward();
        break;
      case GameState.GAMEOVER:
        _gameState = GameState.INIT;
        tap(details);
        break;
    }
  }

  void stop() {
    _levelTimer?.cancel();
    _dinosaurRunAnim.stop();
    _dinosaurJumpAnimCtrl.stop();
    _moveAnim.stop();
  }

  void reset() {
    stop();
    score = 0;
    _moveVelocityPerFrame = 5;
    lastMoveAnimUpdateTime = null;
    _dinosaurState = DinosaurState.STAND;
    treeProducer.treeLists.clear();
  }

  @override
  void dispose() {
    _levelTimer?.cancel();
    _dinosaurRunAnim.dispose();
    _dinosaurJumpAnimCtrl.dispose();
    _moveAnim.dispose();
    super.dispose();
  }
}
