# 恐龙快跑 DinosaurRun

像素风恐龙快跑小游戏。模仿自chrome浏览器网页失败页对应小游戏：[chrome://dino](chrome://dino) <br/>

Pixel wind dinosaur-run small game.


# 效果图

![gif](https://github.com/CCY0122/flutter_dinosaur_run/blob/master/dinosaur_gif.gif)

# 实现


1、使用Flutter自定义绘制：CustomPainter完成恐龙等物体的绘制：<br/>

小技巧：因为是像素风，图像可用二维数组表示： <br/>
<img src="https://github.com/CCY0122/flutter_dinosaur_run/blob/master/pic1.jpg" width = 500/>
<br/> ↓↓↓↓↓   <br/>
<img src="https://github.com/CCY0122/flutter_dinosaur_run/blob/master/pic2.png" width = 500/>
 <br/>然后在`paint`里就可以遍历二维数组，0表示不画，1表示画
<br/>

2、使用Flutter动画：Animation、计时器：Timer 完成动画控制。



<br/><br/>
# 免责
**本作品仅供个人学习，其他使用者也请勿用于利益相关项目，如涉及chrome、google等版权问题，与作者无关。**


