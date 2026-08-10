import 'package:flutter/material.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/presentation/features/company_verifier/company_result_shared.dart';

class CompanySuspiciousScreen extends StatelessWidget {
  const CompanySuspiciousScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Verification Result',
      showBackToHome: true,
      body: CompanyResultBody(),
    );
  }
}
