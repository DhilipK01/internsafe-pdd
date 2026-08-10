import 'package:flutter/material.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/presentation/features/company_verifier/company_result_shared.dart';

class CompanyVerifiedScreen extends StatelessWidget {
  const CompanyVerifiedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Company Verified',
      showBackToHome: true,
      body: CompanyResultBody(),
    );
  }
}
