import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/info_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  Widget _section(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.checkCircle,
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
      title: 'Terms of Service',
      showBackToHome: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'Terms of Service',
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
                    'Welcome to INTERNSAFE',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'By accessing or using our platform, you agree to comply with and be bound by these Terms of Service. Please read them carefully.',
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
              '1. Acceptance of Terms',
              'By signing up, creating an account, or interacting with the INTERNSAFE applications, API services, and web tools, you agree to form a legally binding contract with us. If you do not agree to these terms, you must not use or access any portion of our platform.',
            ),
            _section(
              context,
              '2. Description of Services',
              'INTERNSAFE provides students and young professionals with AI-powered cybersecurity, fraud detection, and safety intelligence for internship offers and applications. Services include document safety scanning, offer verification, company blacklist intelligence, and secure sharing protocols. All verdicts are advisory and do not constitute formal legal counsel.',
            ),
            _section(
              context,
              '3. Accounts and Registration',
              'To access certain tools, you must register an account using a valid email or via Google Sign-In. You are responsible for safeguarding your login credentials and are fully liable for all actions, uploads, and activities performed under your user account.',
            ),
            _section(
              context,
              '4. Data & Document Uploads',
              'You retain ownership of any resumes, offer letters, or files you upload to our scanning engines. By uploading them, you grant INTERNSAFE a license to process and analyze the documents solely for generating safety metrics. Documents are stored in secure databases and can be deleted by you at any time.',
            ),
            _section(
              context,
              '5. Acceptable Use Policy',
              'You agree not to upload malicious payloads (viruses, trojans, etc.), scrape the platform, attempt reverse-engineering of our AI engines, or share reports containing unauthorized personally identifiable information (PII) of third parties without their explicit consent.',
            ),
            _section(
              context,
              '6. Disclaimers & Limitation of Liability',
              'INTERNSAFE services are provided "as is" and "as available". We do not guarantee 100% accuracy of our AI verdicts, nor do we assume liability for any academic, professional, legal, or financial consequences resulting from your choice to accept or decline any internship offers.',
            ),
            _section(
              context,
              '7. Modification of Terms',
              'We reserve the right to revise or update these terms at any time. Continued use of our platform after updates are made constitutes acceptance of the new Terms of Service.',
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
                          'Have questions?',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Contact our legal team at legal@internsafe.app',
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
