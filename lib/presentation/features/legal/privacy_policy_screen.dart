import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/info_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _section(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.shieldCheck,
              color: AppPalette.emeraldBright,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.01,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xl),
          child: Text(
            content,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.mutedColor,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Privacy Policy',
      showBackToHome: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'Privacy Policy',
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Last Updated: May 31, 2026',
              style: context.textTheme.bodySmall?.copyWith(
                color: AppPalette.emeraldBright,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Commitment to Privacy',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Your privacy is our utmost priority. INTERNSAFE is designed from the ground up to secure and protect your personal information while defending you against internship scams.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.mutedColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _section(
              context,
              '1. Information We Collect',
              'We collect information necessary to deliver and secure our services, including: account details (name, email, optional college affiliation), uploaded documents (resumes, internship offer letters), and system logs (IP address, client user-agent) for security metrics and event tracking.',
            ),
            _section(
              context,
              '2. How We Use Information',
              'Your details are processed to: authenticate your user sessions, orchestrate AI-powered document scans, perform company verification lookup, calculate safety/danger indices, and manage your custom shareable links.',
            ),
            _section(
              context,
              '3. Data Storage & Security',
              'All transactional data and user profiles are stored in highly secure Cloudflare D1 SQL databases. File uploads are managed securely and preview options respect browser security parameters. We enforce TLS encryption for all endpoints, API interfaces, and web domains.',
            ),
            _section(
              context,
              '4. Data Sharing and Link Control',
              'INTERNSAFE never sells or rents your personal data. When you generate a "Share Link" for an AI report, it generates a unique token that lets only visitors with that specific link view a masked summary. You can instantly revoke or delete any share link from your dashboard to stop public access.',
            ),
            _section(
              context,
              '5. Data Retention & Deletion',
              'You have full control over your data. If you delete a resume scan, an offer verification, or a uploaded file, it is soft-deleted and all associated public sharing links are instantly revoked and deactivated.',
            ),
            _section(
              context,
              '6. Third-Party Integrations',
              'We utilize Google Sign-In for federated authentication, which operates in compliance with Google OAuth developer requirements. We also integrate Resend for delivering secure transactional One-Time Passwords (OTPs).',
            ),
            _section(
              context,
              '7. Contacting Us About Privacy',
              'If you have questions regarding this policy, want to request complete account deletion, or wish to export your safety data, please reach out to our privacy officer.',
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            InfoCard(
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.mail,
                    color: AppPalette.emeraldBright,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Questions?',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Contact our privacy desk at privacy@internsafe.app',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
