import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/auth_providers.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/dialogs/confirmation_dialog_service.dart';
import 'package:internsfe/application/providers/theme_provider.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/empty_state.dart';
import 'package:internsfe/core/widgets/info_card.dart';
import 'package:internsfe/core/widgets/secondary_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final userAsync = ref.watch(currentUserProvider);

    return AppScaffold(
      title: 'Profile',
      showBackToHome: false,
      showBottomNav: true,
      bottomNavIndex: 4,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Unable to load profile',
          message: '$e',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(currentUserProvider),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserProvider);
              await ref.read(currentUserProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                const InternsafeLogo(size: 72, showGlow: true),
                const SizedBox(height: AppSpacing.lg),
                Text(user.name, style: context.textTheme.headlineMedium),
                Text(user.email, style: context.textTheme.bodySmall),
                if (user.college != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user.college!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                InfoCard(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.history,
                        title: 'History & Statistics',
                        onTap: () => context.push(AppRoutes.history),
                      ),
                      Divider(color: context.borderColor),
                      _SettingsTile(
                        icon: LucideIcons.folderOpen,
                        title: 'My Uploads',
                        subtitle: 'View resumes, offers & documents',
                        onTap: () => context.push(AppRoutes.myUploads),
                      ),
                      Divider(color: context.borderColor),
                      _SettingsTile(
                        icon: LucideIcons.lock,
                        title: 'Privacy Policy',
                        onTap: () => context.push(AppRoutes.privacy),
                      ),
                      Divider(color: context.borderColor),
                      _SettingsTile(
                        icon: LucideIcons.fileText,
                        title: 'Terms of Service',
                        onTap: () => context.push(AppRoutes.terms),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Appearance', style: context.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(LucideIcons.sun, size: 18),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(LucideIcons.moon, size: 18),
                            label: Text('Dark'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(LucideIcons.monitor, size: 18),
                            label: Text('Auto'),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (s) => ref
                            .read(themeModeProvider.notifier)
                            .setTheme(s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                InfoCard(
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shield, color: AppColors.primaryGreen),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Your data is stored in Cloudflare D1.',
                          style: context.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SecondaryButton(
                  label: 'Sign Out',
                  icon: LucideIcons.logOut,
                  onPressed: () async {
                    final ok = await ConfirmationDialogService.confirmAndRun(
                      context: context,
                      request: ConfirmationPresets.signOut,
                      loadingMessage: 'Signing out securely…',
                      successMessage: 'You have been signed out.',
                      action: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        ref.invalidate(currentUserProvider);
                        ref.invalidate(dashboardProvider);
                      },
                    );
                    if (ok && context.mounted) context.go(AppRoutes.login);
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Icon(Icons.chevron_right, color: context.mutedColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
