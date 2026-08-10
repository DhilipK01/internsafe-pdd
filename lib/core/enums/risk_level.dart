import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_palette.dart';

enum RiskLevel { safe, warning, danger, suspicious, genuine, fake }

extension RiskLevelX on RiskLevel {
  Color get color => switch (this) {
        RiskLevel.safe || RiskLevel.genuine => AppPalette.trust,
        RiskLevel.warning || RiskLevel.suspicious => AppPalette.amber,
        RiskLevel.danger || RiskLevel.fake => AppPalette.crimson,
      };

  String get label => switch (this) {
        RiskLevel.safe => 'Safe',
        RiskLevel.warning => 'Warning',
        RiskLevel.danger => 'Danger',
        RiskLevel.suspicious => 'Suspicious',
        RiskLevel.genuine => 'Genuine',
        RiskLevel.fake => 'Fake',
      };
}
