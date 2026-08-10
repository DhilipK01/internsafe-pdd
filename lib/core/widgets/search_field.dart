import 'package:flutter/material.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    this.hint = 'Search...',
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(LucideIcons.search, color: context.mutedColor),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(LucideIcons.x, color: context.mutedColor),
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                },
              )
            : null,
      ),
    );
  }
}
