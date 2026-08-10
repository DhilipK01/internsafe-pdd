import 'package:flutter/material.dart';
import 'package:internsfe/core/widgets/custom_branded_appbar.dart';

/// Legacy alias — prefer [CustomBrandedAppBar].
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.showBackToHome = false,
    this.actions,
  });

  final String title;
  final bool showBackToHome;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(CustomBrandedAppBar.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return CustomBrandedAppBar(
      screenTitle: title,
      showBrand: false,
      showBackToHome: showBackToHome,
      actions: actions,
    );
  }
}
