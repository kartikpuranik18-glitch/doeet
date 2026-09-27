import 'package:doeet/features/auth/presentation/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authErrorMessage', () {
    test('gives actionable feedback for invalid email', () {
      expect(
        authErrorMessage(FirebaseAuthException(code: 'invalid-email')),
        'Enter a valid email address.',
      );
    });

    test('does not reveal whether an email account exists at login', () {
      expect(
        authErrorMessage(FirebaseAuthException(code: 'user-not-found')),
        'Email or password is incorrect.',
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'wrong-password')),
        'Email or password is incorrect.',
      );
    });

    test('explains when a provider is not enabled', () {
      expect(
        authErrorMessage(FirebaseAuthException(code: 'operation-not-allowed')),
        'This sign-in method is not enabled for this app.',
      );
    });
  });
}
