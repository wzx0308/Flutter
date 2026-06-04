import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 屏幕适配工具类
/// 设计基准：375 x 812（iPhone 13 mini）
class R {
  static double get screenWidth => ScreenUtil().screenWidth;
  static double get screenHeight => ScreenUtil().screenHeight;

  /// 宽度适配
  static double w(double value) => value.w;

  /// 高度适配
  static double h(double value) => value.h;

  /// 字体大小适配
  static double sp(double value) => value.sp;

  /// 圆角适配
  static double r(double value) => value.r;

  /// 内边距
  static EdgeInsets padding({
    double horizontal = 0,
    double vertical = 0,
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: left > 0 ? left.w : horizontal.w,
      right: right > 0 ? right.w : horizontal.w,
      top: top > 0 ? top.h : vertical.h,
      bottom: bottom > 0 ? bottom.h : vertical.h,
    );
  }

  /// 对称内边距
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: horizontal.w,
      vertical: vertical.h,
    );
  }

  /// 全部内边距
  static EdgeInsets all(double value) => EdgeInsets.all(value.r);

  /// 根据屏幕宽度返回网格列数
  /// 小屏(<=360) 3列, 标准屏 4列, 大屏(>600) 5列
  static int gridCrossAxisCount({int base = 4}) {
    if (screenWidth <= 360) return base - 1;
    if (screenWidth > 600) return base + 1;
    return base;
  }

  /// 图片网格列数
  /// 根据图片数量和屏幕宽度动态计算
  static int imageGridCount(int imageCount) {
    if (imageCount == 1) return 1;
    if (imageCount == 2) return 2;
    if (screenWidth <= 360) return 2;
    return 3;
  }

  /// 图片网格中的单张图片尺寸
  static double imageGridSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = 24.w; // 卡片左右 padding
    final spacing = 6.w;
    if (width <= 360) {
      return (width - padding - spacing) / 2;
    }
    return (width - padding - spacing * 2) / 3;
  }
}
