import 'package:flutter/material.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/presentation/features/offer_detector/offer_result_shared.dart';

class OfferGenuineResultScreen extends StatelessWidget {
  const OfferGenuineResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Offer Submitted',
      showBackToHome: true,
      body: OfferResultBody(),
    );
  }
}
