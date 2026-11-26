import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jump_and_learn/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('Sign in requires an email and password', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your email and password.'), findsOneWidget);
  });
}