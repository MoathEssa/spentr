import 'package:flutter_test/flutter_test.dart';
import 'package:spentr/ui/screens/sign_in_screen.dart';

/// Fills the Sign in form with valid details and submits it.
Future<void> signIn(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(SignInScreen.emailFieldKey), 'freelancer@example.com');
  await tester.enterText(
      find.byKey(SignInScreen.passwordFieldKey), 'password123');
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

/// Fills the Create account form with valid details (does not submit).
Future<void> fillSignUp(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(SignInScreen.emailFieldKey), 'freelancer@example.com');
  await tester.enterText(
      find.byKey(SignInScreen.passwordFieldKey), 'password123');
  await tester.enterText(
      find.byKey(SignInScreen.confirmFieldKey), 'password123');
}
