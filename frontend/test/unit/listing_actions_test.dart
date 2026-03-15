import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vedgy/models/listing.dart';
import 'package:vedgy/providers/listing_actions_provider.dart';
import 'package:vedgy/services/api_client.dart';

import '../helpers/test_fixtures.dart';
import '../integration/helpers/mock_dio.dart';

void main() {
  late MockDio mockDio;
  late ProviderContainer container;

  setUp(() {
    mockDio = MockDio();
    container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(mockDio)],
    );
  });

  tearDown(() => container.dispose());

  group('ListingActions', () {
    test(
      'createListing sends POST to /api/listings/ and returns Listing',
      () async {
        final fields = {'title': 'New Listing', 'city': 'New York'};
        when(
          () => mockDio.post<Map<String, dynamic>>(
            '/api/listings/',
            data: fields,
          ),
        ).thenAnswer(
          (_) async => okResponse(testListingJson, '/api/listings/'),
        );

        final actions = container.read(listingActionsProvider);
        final result = await actions.createListing(fields);

        expect(result, isA<Listing>());
        expect(result.title, 'Cozy Vegan Room');
        verify(
          () => mockDio.post<Map<String, dynamic>>(
            '/api/listings/',
            data: fields,
          ),
        ).called(1);
      },
    );

    test(
      'updateListing sends PATCH to /api/listings/:id/ and returns Listing',
      () async {
        final fields = {'title': 'Updated Title'};
        when(
          () => mockDio.patch<Map<String, dynamic>>(
            '/api/listings/listing-uuid-001/',
            data: fields,
          ),
        ).thenAnswer(
          (_) async =>
              okResponse(testListingJson, '/api/listings/listing-uuid-001/'),
        );

        final actions = container.read(listingActionsProvider);
        final result = await actions.updateListing('listing-uuid-001', fields);

        expect(result, isA<Listing>());
        verify(
          () => mockDio.patch<Map<String, dynamic>>(
            '/api/listings/listing-uuid-001/',
            data: fields,
          ),
        ).called(1);
      },
    );

    test('deleteListing sends DELETE to /api/listings/:id/', () async {
      when(
        () => mockDio.delete<void>('/api/listings/listing-uuid-001/'),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(
            path: '/api/listings/listing-uuid-001/',
          ),
        ),
      );

      final actions = container.read(listingActionsProvider);
      await actions.deleteListing('listing-uuid-001');

      verify(
        () => mockDio.delete<void>('/api/listings/listing-uuid-001/'),
      ).called(1);
    });

    test(
      'deactivateListing sends POST to /api/listings/:id/deactivate/',
      () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            '/api/listings/listing-uuid-001/deactivate/',
          ),
        ).thenAnswer(
          (_) async => okResponse({
            ...testListingJson,
            'status': 'deactivated',
          }, '/api/listings/listing-uuid-001/deactivate/'),
        );

        final actions = container.read(listingActionsProvider);
        final result = await actions.deactivateListing('listing-uuid-001');

        expect(result, isA<Listing>());
        verify(
          () => mockDio.post<Map<String, dynamic>>(
            '/api/listings/listing-uuid-001/deactivate/',
          ),
        ).called(1);
      },
    );

    test('submitForReview sends POST to /api/listings/:id/submit/', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/listings/listing-uuid-001/submit/',
        ),
      ).thenAnswer(
        (_) async => okResponse({
          ...testListingJson,
          'status': 'payment_submitted',
        }, '/api/listings/listing-uuid-001/submit/'),
      );

      final actions = container.read(listingActionsProvider);
      final result = await actions.submitForReview('listing-uuid-001');

      expect(result, isA<Listing>());
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/listings/listing-uuid-001/submit/',
        ),
      ).called(1);
    });

    test('createListing propagates DioException on failure', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/listings/',
          data: any(named: 'data'),
        ),
      ).thenThrow(dioError('/api/listings/', statusCode: 400));

      final actions = container.read(listingActionsProvider);

      expect(
        () => actions.createListing({'title': 'Bad'}),
        throwsA(isA<DioException>()),
      );
    });
  });
}
