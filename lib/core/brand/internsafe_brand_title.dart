import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/theme/brand_typography.dart';

/// Centered "Internsafe AI" — Grand Hotel + emerald "AI" suffix.
class InternsafeBrandTitle extends StatelessWidget {
  const InternsafeBrandTitle({
    super.key,
    this.logoSize = 28,
    this.showLogo = true,
    this.compact = false,
    this.large = false,
  });

  final double logoSize;
  final bool showLogo;
  final bool compact;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final titleSize = large ? 40.0 : (compact ? 26.0 : 34.0);
    final aiSize = large ? 17.0 : (compact ? 12.0 : 14.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showLogo && logoSize > 0) ...[
          InternsafeLogo(size: logoSize, showGlow: !compact),
          SizedBox(width: compact ? 6 : 8),
        ],
        Baseline(
          baseline: titleSize * 0.78,
          baselineType: TextBaseline.alphabetic,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Internsafe',
                style: BrandTypography.appTitle(
                  context,
                  fontSize: titleSize,
                ),
              ),
              Text(
                ' AI',
                style: BrandTypography.appTitleAi(context, fontSize: aiSize),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
