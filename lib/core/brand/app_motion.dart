import 'package:flutter/animation.dart';

/// Apple-grade motion curves for INTERNSAFE.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration splash = Duration(milliseconds: 2400);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve decel = Curves.decelerate;
}
