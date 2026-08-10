import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/constants/brand_assets.dart';

/// Renders the official INTERNSAFE AI logo from [BrandAssets.logo] only.
class InternsafeLogo extends StatelessWidget {
  const InternsafeLogo({
    super.key,
    this.size = 80,
    this.animate = false,
    this.monochrome = false,
    this.showGlow = false,
    this.semanticLabel = 'Internsafe AI',
  });

  final double size;
  final bool animate;
  final bool monochrome;
  final bool showGlow;
  final String semanticLabel;

  static ImageProvider provider({AssetBundle? bundle}) {
    return AssetImage(BrandAssets.logo, bundle: bundle);
  }

  /// Preload the logo for splash / cold start (call after first frame).
  static Future<void> precache(BuildContext context) {
    return precacheImage(provider(), context);
  }

  @override
  Widget build(BuildContext context) {
    Widget logo = Image(
      image: provider(),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      semanticLabel: semanticLabel,
      excludeFromSemantics: false,
    );

    if (monochrome) {
      logo = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: logo,
      );
    }

    if (showGlow) {
      logo = DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppPalette.emeraldBright.withValues(alpha: 0.28),
              blurRadius: size * 0.28,
              spreadRadius: 0,
            ),
          ],
        ),
        child: logo,
      );
    }

    if (animate) {
      logo = logo
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.97, 0.97),
            end: const Offset(1.03, 1.03),
            duration: 2200.ms,
            curve: Curves.easeInOut,
          );
    }

    return Semantics(label: semanticLabel, image: true, child: logo);
  }
}

/// Animated splash reveal for the official logo.
class InternsafeLogoReveal extends StatefulWidget {
  const InternsafeLogoReveal({super.key, this.size = 120});

  final double size;

  @override
  State<InternsafeLogoReveal> createState() => _InternsafeLogoRevealState();
}

class _InternsafeLogoRevealState extends State<InternsafeLogoReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Transform.scale(
          scale: 0.6 + 0.4 * t,
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: InternsafeLogo(size: widget.size, showGlow: true),
          ),
        );
      },
    );
  }
}
