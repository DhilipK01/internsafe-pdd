import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/brand_assets.dart';

void main() {
  testWidgets('Official brand logo renders from BrandAssets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: InternsafeLogo(size: 48))),
      ),
    );
    expect(find.byType(InternsafeLogo), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, BrandAssets.logo);
  });
}
