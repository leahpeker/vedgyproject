import 'package:flutter_test/flutter_test.dart';
import 'package:vedgy/models/listing.dart';

import '../helpers/test_fixtures.dart';

void main() {
  group('Listing.fromJson', () {
    test('parses all required fields correctly', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.id, equals('listing-uuid-001'));
      expect(listing.title, equals('Cozy Vegan Room'));
      expect(listing.description, equals('Nice place.'));
      expect(listing.city, equals('New York'));
      expect(listing.rentalType, equals('sublet'));
      expect(listing.roomType, equals('private_room'));
      expect(listing.veganHousehold, equals('fully_vegan'));
      expect(listing.furnished, equals('furnished'));
      expect(listing.listerRelationship, equals('owner'));
      expect(listing.status, equals('active'));
    });

    test('parses optional string fields correctly', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.borough, equals('Brooklyn'));
      expect(listing.neighborhood, isNull);
    });

    test('parses numeric fields correctly', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.price, equals(1200));
    });

    test('parses boolean fields correctly', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.seekingRoommate, isFalse);
      expect(listing.includePhone, isFalse);
    });

    test('parses createdAt datetime correctly', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.createdAt, equals(DateTime.utc(2026, 1, 1)));
    });

    test('parses nested user object correctly', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.user.id, equals('user-uuid-001'));
      expect(listing.user.firstName, equals('Test'));
      expect(listing.user.lastName, equals('User'));
    });
  });

  group('Listing null optional fields', () {
    test('null end_date results in null endDate', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.endDate, isNull);
    });

    test('null start_date results in null startDate', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.startDate, isNull);
    });

    test('null expires_at results in null expiresAt', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.expiresAt, isNull);
    });

    test('null about_lister results in null aboutLister', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.aboutLister, isNull);
    });

    test('null rental_requirements results in null rentalRequirements', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.rentalRequirements, isNull);
    });

    test('null pet_policy results in null petPolicy', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.petPolicy, isNull);
    });

    test('null phone_number results in null phoneNumber', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.phoneNumber, isNull);
    });
  });

  group('Listing status', () {
    test('active status maps to "active" string', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.status, equals('active'));
    });

    test('draft status is preserved correctly', () {
      final json = Map<String, dynamic>.from(testListingJson)
        ..['status'] = 'draft';
      final listing = Listing.fromJson(json);

      expect(listing.status, equals('draft'));
    });

    test('payment_submitted status is preserved correctly', () {
      final json = Map<String, dynamic>.from(testListingJson)
        ..['status'] = 'payment_submitted';
      final listing = Listing.fromJson(json);

      expect(listing.status, equals('payment_submitted'));
    });

    test('expired status is preserved correctly', () {
      final json = Map<String, dynamic>.from(testListingJson)
        ..['status'] = 'expired';
      final listing = Listing.fromJson(json);

      expect(listing.status, equals('expired'));
    });
  });

  group('Listing photos', () {
    test('empty photos array results in empty list', () {
      final listing = Listing.fromJson(testListingJson);

      expect(listing.photos, isEmpty);
    });

    test('photos array with items parses correctly', () {
      final json = Map<String, dynamic>.from(testListingJson)
        ..['photos'] = [
          {
            'id': 'photo-uuid-001',
            'filename': 'photo1.jpg',
            'url': 'https://example.com/photos/photo1.jpg',
          },
          {
            'id': 'photo-uuid-002',
            'filename': 'photo2.jpg',
            'url': 'https://example.com/photos/photo2.jpg',
          },
        ];
      final listing = Listing.fromJson(json);

      expect(listing.photos.length, equals(2));
      expect(listing.photos[0].id, equals('photo-uuid-001'));
      expect(listing.photos[0].filename, equals('photo1.jpg'));
      expect(listing.photos[0].url, equals('https://example.com/photos/photo1.jpg'));
      expect(listing.photos[1].id, equals('photo-uuid-002'));
      expect(listing.photos[1].url, equals('https://example.com/photos/photo2.jpg'));
    });

    test('photos list has correct length', () {
      final json = Map<String, dynamic>.from(testListingJson)
        ..['photos'] = [
          {
            'id': 'photo-uuid-001',
            'filename': 'photo1.jpg',
            'url': 'https://example.com/photos/photo1.jpg',
          },
        ];
      final listing = Listing.fromJson(json);

      expect(listing.photos.length, equals(1));
    });
  });

  group('Listing.toJson', () {
    test('serializes key fields back to JSON', () {
      final json = Listing.fromJson(testListingJson).toJson();

      expect(json['id'], equals('listing-uuid-001'));
      expect(json['title'], equals('Cozy Vegan Room'));
      expect(json['description'], equals('Nice place.'));
      expect(json['city'], equals('New York'));
      expect(json['status'], equals('active'));
    });

    test('serializes optional fields with correct keys', () {
      final json = Listing.fromJson(testListingJson).toJson();

      expect(json['borough'], equals('Brooklyn'));
      expect(json['neighborhood'], isNull);
      expect(json['price'], equals(1200));
    });

    test('serializes boolean fields correctly', () {
      final json = Listing.fromJson(testListingJson).toJson();

      expect(json['seeking_roommate'], isFalse);
      expect(json['include_phone'], isFalse);
    });

    test('serializes null date fields as null', () {
      final json = Listing.fromJson(testListingJson).toJson();

      expect(json['start_date'], isNull);
      expect(json['end_date'], isNull);
      expect(json['expires_at'], isNull);
    });

    test('serializes nested user object', () {
      final json = Listing.fromJson(testListingJson).toJson();
      final userJson = json['user'] as Map<String, dynamic>;

      expect(userJson['id'], equals('user-uuid-001'));
      expect(userJson['first_name'], equals('Test'));
      expect(userJson['last_name'], equals('User'));
    });

    test('serializes empty photos as empty list', () {
      final json = Listing.fromJson(testListingJson).toJson();

      expect(json['photos'], isEmpty);
    });
  });

  group('Listing round-trip', () {
    test('fromJson then toJson preserves id', () {
      final json = Listing.fromJson(testListingJson).toJson();
      expect(json['id'], equals(testListingJson['id']));
    });

    test('fromJson then toJson preserves title', () {
      final json = Listing.fromJson(testListingJson).toJson();
      expect(json['title'], equals(testListingJson['title']));
    });

    test('fromJson then toJson preserves city', () {
      final json = Listing.fromJson(testListingJson).toJson();
      expect(json['city'], equals(testListingJson['city']));
    });

    test('fromJson then toJson preserves status', () {
      final json = Listing.fromJson(testListingJson).toJson();
      expect(json['status'], equals(testListingJson['status']));
    });

    test('fromJson then toJson preserves rental_type', () {
      final json = Listing.fromJson(testListingJson).toJson();
      expect(json['rental_type'], equals(testListingJson['rental_type']));
    });

    test('fromJson then toJson preserves room_type', () {
      final json = Listing.fromJson(testListingJson).toJson();
      expect(json['room_type'], equals(testListingJson['room_type']));
    });

    test('fromJson then toJson preserves vegan_household', () {
      final json = Listing.fromJson(testListingJson).toJson();
      expect(json['vegan_household'], equals(testListingJson['vegan_household']));
    });

    test('second round-trip produces same result as first', () {
      final firstPass = Listing.fromJson(testListingJson).toJson();
      final secondPass = Listing.fromJson(firstPass).toJson();

      expect(secondPass['id'], equals(firstPass['id']));
      expect(secondPass['title'], equals(firstPass['title']));
      expect(secondPass['status'], equals(firstPass['status']));
      expect(secondPass['city'], equals(firstPass['city']));
      expect(secondPass['rental_type'], equals(firstPass['rental_type']));
    });

    test('createdAt serializes as ISO 8601 string', () {
      final json = Listing.fromJson(testListingJson).toJson();

      expect(json['created_at'], isA<String>());
      expect(json['created_at'] as String, contains('2026-01-01'));
    });

    test('photos round-trip preserves photo data', () {
      final inputJson = Map<String, dynamic>.from(testListingJson)
        ..['photos'] = [
          {
            'id': 'photo-uuid-001',
            'filename': 'photo1.jpg',
            'url': 'https://example.com/photos/photo1.jpg',
          },
        ];

      final outputJson = Listing.fromJson(inputJson).toJson();
      final photos = outputJson['photos'] as List<dynamic>;

      expect(photos.length, equals(1));
      final photo = photos[0] as Map<String, dynamic>;
      expect(photo['id'], equals('photo-uuid-001'));
      expect(photo['filename'], equals('photo1.jpg'));
      expect(photo['url'], equals('https://example.com/photos/photo1.jpg'));
    });
  });
}
