import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hungry/pages/product/widgets/product_app_bar.dart';

void main() {
  testWidgets('ProductAppBar renders title without action icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductAppBar(
            text: 'Settings',
            padiing: 0,
            showbackicon: false,
          ),
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsNothing);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
  });
}
