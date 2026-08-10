import 'package:flutter/material.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum VerificationStatus { verified, partial, failed }

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({
    super.key,
    required this.label,
    required this.status,
    this.detail,
  });

  final String label;
  final VerificationStatus status;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      VerificationStatus.verified => (
          const Color(0xFF2ECC71),
          LucideIcons.checkCircle2
        ),
      VerificationStatus.partial => (
          const Color(0xFFFF8F00),
          LucideIcons.alertCircle
        ),
      VerificationStatus.failed => (
          const Color(0xFFE53935),
          LucideIcons.xCircle
        ),
    };

    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.textTheme.titleMedium),
              if (detail != null)
                Text(detail!, style: context.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
