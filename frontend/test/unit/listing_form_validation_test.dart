// Unit tests for the listing form validation logic.
//
// Tests exercise the production `validateListingForm()` function from
// `lib/widgets/listing_form_validators.dart` directly.

import 'package:flutter_test/flutter_test.dart';

import 'package:vedgy/widgets/listing_form_validators.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ---- Title ---------------------------------------------------------------

  group('validateListingForm title validation', () {
    test('empty title returns "Title is required."', () {
      final errors = validateListingForm(title: '', city: 'New York');
      expect(errors, contains('Title is required.'));
    });

    test('whitespace-only title returns "Title is required."', () {
      final errors = validateListingForm(title: '   ', city: 'New York');
      expect(errors, contains('Title is required.'));
    });

    test('tab character title returns "Title is required."', () {
      final errors = validateListingForm(title: '\t', city: 'New York');
      expect(errors, contains('Title is required.'));
    });

    test('non-empty title does not produce title error', () {
      final errors = validateListingForm(
        title: 'Cozy room in vegan house',
        city: 'New York',
      );
      expect(errors, isNot(contains('Title is required.')));
    });

    test('title with surrounding whitespace does not produce error', () {
      final errors = validateListingForm(
        title: '  Sunny studio  ',
        city: 'New York',
      );
      expect(errors, isNot(contains('Title is required.')));
    });

    test('single character title does not produce error', () {
      final errors = validateListingForm(title: 'A', city: 'New York');
      expect(errors, isNot(contains('Title is required.')));
    });
  });

  // ---- City ----------------------------------------------------------------

  group('validateListingForm city validation', () {
    test('null city returns "City is required."', () {
      final errors = validateListingForm(title: 'Test', city: null);
      expect(errors, contains('City is required.'));
    });

    test('"New York" does not produce city error', () {
      final errors = validateListingForm(title: 'Test', city: 'New York');
      expect(errors, isNot(contains('City is required.')));
    });

    test('"Los Angeles" does not produce city error', () {
      final errors = validateListingForm(title: 'Test', city: 'Los Angeles');
      expect(errors, isNot(contains('City is required.')));
    });

    test('arbitrary non-null string does not produce city error', () {
      final errors = validateListingForm(title: 'Test', city: 'Boston');
      expect(errors, isNot(contains('City is required.')));
    });
  });

  // ---- Price ---------------------------------------------------------------

  group('validateListingForm price validation', () {
    test('empty price is allowed (optional field)', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        price: '',
      );
      expect(errors, isNot(contains('Price must be a positive whole number.')));
    });

    test('whitespace-only price is allowed', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        price: '   ',
      );
      expect(errors, isNot(contains('Price must be a positive whole number.')));
    });

    test('non-numeric text returns price error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        price: 'abc',
      );
      expect(errors, contains('Price must be a positive whole number.'));
    });

    test('float string returns price error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        price: '12.50',
      );
      expect(errors, contains('Price must be a positive whole number.'));
    });

    test('"0" returns price error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        price: '0',
      );
      expect(errors, contains('Price must be a positive whole number.'));
    });

    test('negative number returns price error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        price: '-500',
      );
      expect(errors, contains('Price must be a positive whole number.'));
    });

    test('"1" does not produce price error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        price: '1',
      );
      expect(errors, isNot(contains('Price must be a positive whole number.')));
    });

    test('"1200" does not produce price error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        price: '1200',
      );
      expect(errors, isNot(contains('Price must be a positive whole number.')));
    });

    test('price with surrounding whitespace "  800  " is valid', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        price: '  800  ',
      );
      expect(errors, isNot(contains('Price must be a positive whole number.')));
    });

    test('mixed letters and digits returns price error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        price: '12abc',
      );
      expect(errors, contains('Price must be a positive whole number.'));
    });
  });

  // ---- Date validation -----------------------------------------------------

  group('validateListingForm date validation', () {
    test('start date after end date returns error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        startDate: '2026-06-15',
        endDate: '2026-03-01',
      );
      expect(errors, contains('Start date must be before end date.'));
    });

    test('start date before end date does not produce error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        startDate: '2026-03-01',
        endDate: '2026-06-15',
      );
      expect(
        errors,
        isNot(contains('Start date must be before end date.')),
      );
    });

    test('same start and end date does not produce error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        startDate: '2026-06-01',
        endDate: '2026-06-01',
      );
      expect(
        errors,
        isNot(contains('Start date must be before end date.')),
      );
    });

    test('only start date provided does not produce date error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        startDate: '2026-06-01',
      );
      expect(
        errors,
        isNot(contains('Start date must be before end date.')),
      );
    });

    test('only end date provided does not produce date error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        endDate: '2026-06-01',
      );
      expect(
        errors,
        isNot(contains('Start date must be before end date.')),
      );
    });

    test('invalid date strings do not produce date error', () {
      final errors = validateListingForm(
        title: 'Test',
        city: 'NYC',
        startDate: 'not-a-date',
        endDate: 'also-not-a-date',
      );
      expect(
        errors,
        isNot(contains('Start date must be before end date.')),
      );
    });
  });

  // ---- Full form validation ------------------------------------------------

  group('validateListingForm combined', () {
    test('all valid fields returns empty error list', () {
      final errors = validateListingForm(
        title: 'Bright room in Brooklyn',
        city: 'New York',
        price: '1500',
      );
      expect(errors, isEmpty);
    });

    test('empty title and null city produce two errors', () {
      final errors = validateListingForm(
        title: '',
        city: null,
      );
      expect(errors.length, 2);
      expect(
        errors,
        containsAll(['Title is required.', 'City is required.']),
      );
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

    test('empty price with valid title and city returns no errors', () {
      final errors = validateListingForm(
        title: 'Cozy room',
        city: 'Chicago',
      );
      expect(errors, isEmpty);
    });

    test('all invalid including bad dates produce four errors', () {
      final errors = validateListingForm(
        title: '',
        city: null,
        price: 'free',
        startDate: '2026-12-01',
        endDate: '2026-01-01',
      );
      expect(errors.length, 4);
    });
  });
}
