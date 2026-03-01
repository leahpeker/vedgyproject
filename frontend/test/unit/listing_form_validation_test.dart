// Unit tests for the ListingForm validation logic.
//
// The validation lives in `_ListingFormState._validate()` inside
// `lib/widgets/listing_form.dart`.  Because that method is private and tied to
// widget state, we mirror the exact logic as standalone helper functions here
// and test those directly with plain `test()` calls (no widgets involved).
//
// Validation rules (as implemented in _validate()):
//   Title  – required; _title.text.trim() must not be empty.
//   City   – required; _city must not be null.
//   Price  – optional; if the trimmed text is non-empty it must parse as int
//            and the parsed value must be > 0.

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers that mirror _ListingFormState._validate() logic
// ---------------------------------------------------------------------------

/// Returns 'Title is required.' when the trimmed value is empty, else null.
String? validateTitle(String? value) {
  if (value == null || value.trim().isEmpty) return 'Title is required.';
  return null;
}

/// Returns 'City is required.' when city is null, else null.
String? validateCity(String? city) {
  if (city == null) return 'City is required.';
  return null;
}

/// Returns an error message when the price text is present but invalid,
/// else null.
///
/// Rules (from _validate):
///   - empty / whitespace-only → no error (field is optional)
///   - non-numeric             → 'Price must be a positive whole number.'
///   - zero                    → 'Price must be a positive whole number.'
///   - negative                → 'Price must be a positive whole number.'
///   - positive integer        → null (valid)
String? validatePrice(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null; // optional field
  final parsed = int.tryParse(text);
  if (parsed == null || parsed <= 0) {
    return 'Price must be a positive whole number.';
  }
  return null;
}

/// Mirrors the full _validate() method, collecting all errors.
List<String> validateListingForm({
  required String title,
  required String? city,
  required String price,
}) {
  final errors = <String>[];
  final titleError = validateTitle(title);
  if (titleError != null) errors.add(titleError);
  final cityError = validateCity(city);
  if (cityError != null) errors.add(cityError);
  final priceError = validatePrice(price);
  if (priceError != null) errors.add(priceError);
  return errors;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ---- Title ---------------------------------------------------------------

  group('validateTitle', () {
    test('null returns "Title is required."', () {
      expect(validateTitle(null), 'Title is required.');
    });

    test('empty string returns "Title is required."', () {
      expect(validateTitle(''), 'Title is required.');
    });

    test('whitespace-only returns "Title is required."', () {
      expect(validateTitle('   '), 'Title is required.');
    });

    test('tab character returns "Title is required."', () {
      expect(validateTitle('\t'), 'Title is required.');
    });

    test('non-empty title returns null', () {
      expect(validateTitle('Cozy room in vegan house'), isNull);
    });

    test('title with surrounding whitespace returns null (trimmed)', () {
      expect(validateTitle('  Sunny studio  '), isNull);
    });

    test('single character title returns null', () {
      expect(validateTitle('A'), isNull);
    });
  });

  // ---- City ----------------------------------------------------------------

  group('validateCity', () {
    test('null city returns "City is required."', () {
      expect(validateCity(null), 'City is required.');
    });

    test('"New York" returns null', () {
      expect(validateCity('New York'), isNull);
    });

    test('"Los Angeles" returns null', () {
      expect(validateCity('Los Angeles'), isNull);
    });

    test('"Chicago" returns null', () {
      expect(validateCity('Chicago'), isNull);
    });

    test('arbitrary non-null string returns null (no allowlist check)', () {
      expect(validateCity('Boston'), isNull);
    });
  });

  // ---- Price ---------------------------------------------------------------

  group('validatePrice', () {
    test('null returns null (optional field)', () {
      expect(validatePrice(null), isNull);
    });

    test('empty string returns null (optional field)', () {
      expect(validatePrice(''), isNull);
    });

    test('whitespace-only returns null (optional field)', () {
      expect(validatePrice('   '), isNull);
    });

    test('non-numeric text returns error message', () {
      expect(
        validatePrice('abc'),
        'Price must be a positive whole number.',
      );
    });

    test('float string returns error message', () {
      expect(
        validatePrice('12.50'),
        'Price must be a positive whole number.',
      );
    });

    test('"0" returns error message', () {
      expect(
        validatePrice('0'),
        'Price must be a positive whole number.',
      );
    });

    test('negative number returns error message', () {
      expect(
        validatePrice('-500'),
        'Price must be a positive whole number.',
      );
    });

    test('"1" returns null (minimum positive value)', () {
      expect(validatePrice('1'), isNull);
    });

    test('typical rent value "1200" returns null', () {
      expect(validatePrice('1200'), isNull);
    });

    test('large value "9999" returns null', () {
      expect(validatePrice('9999'), isNull);
    });

    test('price with surrounding whitespace "  800  " returns null (trimmed)',
        () {
      expect(validatePrice('  800  '), isNull);
    });

    test('price that is letters mixed with digits returns error message', () {
      expect(
        validatePrice('12abc'),
        'Price must be a positive whole number.',
      );
    });
  });

  // ---- Full form validation (mirrors _validate()) --------------------------

  group('validateListingForm', () {
    test('all valid fields returns empty error list', () {
      final errors = validateListingForm(
        title: 'Bright room in Brooklyn',
        city: 'New York',
        price: '1500',
      );
      expect(errors, isEmpty);
    });

    test('empty title adds title error', () {
      final errors = validateListingForm(
        title: '',
        city: 'Chicago',
        price: '800',
      );
      expect(errors, contains('Title is required.'));
      expect(errors.length, 1);
    });

    test('null city adds city error', () {
      final errors = validateListingForm(
        title: 'Studio near the park',
        city: null,
        price: '950',
      );
      expect(errors, contains('City is required.'));
      expect(errors.length, 1);
    });

    test('invalid price adds price error', () {
      final errors = validateListingForm(
        title: 'Sunny loft',
        city: 'Los Angeles',
        price: 'free',
      );
      expect(errors, contains('Price must be a positive whole number.'));
      expect(errors.length, 1);
    });

    test('zero price adds price error', () {
      final errors = validateListingForm(
        title: 'Sunny loft',
        city: 'Los Angeles',
        price: '0',
      );
      expect(errors, contains('Price must be a positive whole number.'));
    });

    test('empty title and null city produce two errors', () {
      final errors = validateListingForm(
        title: '',
        city: null,
        price: '',
      );
      expect(errors.length, 2);
      expect(errors, containsAll(['Title is required.', 'City is required.']));
    });

    test('all invalid fields produce three errors', () {
      final errors = validateListingForm(
        title: '  ',
        city: null,
        price: '-100',
      );
      expect(errors.length, 3);
      expect(
        errors,
        containsAll([
          'Title is required.',
          'City is required.',
          'Price must be a positive whole number.',
        ]),
      );
    });

    test('empty price is allowed (price is optional)', () {
      final errors = validateListingForm(
        title: 'Cozy room',
        city: 'Chicago',
        price: '',
      );
      expect(errors, isEmpty);
    });
  });
}
