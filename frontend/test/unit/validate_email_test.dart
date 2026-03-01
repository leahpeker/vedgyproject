import 'package:flutter_test/flutter_test.dart';
import 'package:vedgy/widgets/error_banner.dart';

void main() {
  group('validateEmail', () {
    // --- Required-field cases ---

    test('null input returns "Email is required"', () {
      expect(validateEmail(null), 'Email is required');
    });

    test('empty string returns "Email is required"', () {
      expect(validateEmail(''), 'Email is required');
    });

    test('whitespace-only string returns "Email is required"', () {
      expect(validateEmail('   '), 'Email is required');
    });

    test('tab character returns "Email is required"', () {
      expect(validateEmail('\t'), 'Email is required');
    });

    // --- Valid email cases ---

    test('valid email returns null', () {
      expect(validateEmail('user@example.com'), isNull);
    });

    test('subdomain email returns null', () {
      expect(validateEmail('user@mail.example.co.uk'), isNull);
    });

    test('email with plus tag returns null', () {
      expect(validateEmail('user+tag@example.com'), isNull);
    });

    test('whitespace-padded valid email returns null (trims before validating)',
        () {
      expect(validateEmail('  user@example.com  '), isNull);
    });

    // --- Invalid format cases ---

    test('missing @ returns "Enter a valid email address"', () {
      expect(validateEmail('userexample.com'), 'Enter a valid email address');
    });

    test('missing TLD returns "Enter a valid email address"', () {
      expect(validateEmail('user@example'), 'Enter a valid email address');
    });

    test('space inside email returns "Enter a valid email address"', () {
      expect(validateEmail('user @example.com'), 'Enter a valid email address');
    });

    test('double @ returns "Enter a valid email address"', () {
      expect(validateEmail('user@@example.com'), 'Enter a valid email address');
    });

    test('empty local part returns "Enter a valid email address"', () {
      expect(validateEmail('@example.com'), 'Enter a valid email address');
    });
  });
}
