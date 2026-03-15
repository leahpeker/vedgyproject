import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vedgy/models/listing.dart';
import 'package:vedgy/providers/photo_provider.dart';
import 'package:vedgy/services/api_client.dart';

import '../integration/helpers/mock_dio.dart';

class MockXFile extends Mock implements XFile {}

void main() {
  late MockDio mockDio;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FormData());
  });

  setUp(() {
    mockDio = MockDio();
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockDio),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('PhotoActions', () {
    test('uploadPhotos sends POST with multipart form data and returns photos',
        () async {
      final xfile = MockXFile();
      when(() => xfile.readAsBytes())
          .thenAnswer((_) async => Uint8List.fromList([0, 1, 2]));
      when(() => xfile.name).thenReturn('test.jpg');

      const photoJson = <String, dynamic>{
        'id': 'photo-uuid-001',
        'filename': 'test.jpg',
        'url': 'https://example.com/test.jpg',
      };

      when(() => mockDio.post<Map<String, dynamic>>(
            '/api/listings/listing-uuid-001/photos/',
            data: any(named: 'data'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async => okResponse(
            photoJson,
            '/api/listings/listing-uuid-001/photos/',
          ));

      final actions = container.read(photoActionsProvider);
      final result = await actions.uploadPhotos('listing-uuid-001', [xfile]);

      expect(result, hasLength(1));
      expect(result.first, isA<ListingPhoto>());
      expect(result.first.filename, 'test.jpg');
      verify(() => mockDio.post<Map<String, dynamic>>(
            '/api/listings/listing-uuid-001/photos/',
            data: any(named: 'data'),
            onSendProgress: any(named: 'onSendProgress'),
          )).called(1);
    });

    test('uploadPhotos uploads multiple files sequentially', () async {
      final xfile1 = MockXFile();
      final xfile2 = MockXFile();
      when(() => xfile1.readAsBytes())
          .thenAnswer((_) async => Uint8List.fromList([0]));
      when(() => xfile1.name).thenReturn('photo1.jpg');
      when(() => xfile2.readAsBytes())
          .thenAnswer((_) async => Uint8List.fromList([1]));
      when(() => xfile2.name).thenReturn('photo2.jpg');

      var callCount = 0;
      when(() => mockDio.post<Map<String, dynamic>>(
            '/api/listings/listing-uuid-001/photos/',
            data: any(named: 'data'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async {
        callCount++;
        return okResponse(
          {
            'id': 'photo-uuid-00$callCount',
            'filename': 'photo$callCount.jpg',
            'url': 'https://example.com/photo$callCount.jpg',
          },
          '/api/listings/listing-uuid-001/photos/',
        );
      });

      final actions = container.read(photoActionsProvider);
      final result =
          await actions.uploadPhotos('listing-uuid-001', [xfile1, xfile2]);

      expect(result, hasLength(2));
      expect(result[0].filename, 'photo1.jpg');
      expect(result[1].filename, 'photo2.jpg');
      verify(() => mockDio.post<Map<String, dynamic>>(
            '/api/listings/listing-uuid-001/photos/',
            data: any(named: 'data'),
            onSendProgress: any(named: 'onSendProgress'),
          )).called(2);
    });

    test('deletePhoto sends DELETE to /api/listings/photos/:id/', () async {
      when(() => mockDio.delete<void>('/api/listings/photos/photo-uuid-001/'))
          .thenAnswer((_) async => Response(
                statusCode: 204,
                requestOptions:
                    RequestOptions(path: '/api/listings/photos/photo-uuid-001/'),
              ));

      final actions = container.read(photoActionsProvider);
      await actions.deletePhoto('listing-uuid-001', 'photo-uuid-001');

      verify(() => mockDio.delete<void>('/api/listings/photos/photo-uuid-001/'))
          .called(1);
    });

    test('uploadPhotos propagates DioException on failure', () async {
      final xfile = MockXFile();
      when(() => xfile.readAsBytes())
          .thenAnswer((_) async => Uint8List.fromList([0]));
      when(() => xfile.name).thenReturn('test.jpg');

      when(() => mockDio.post<Map<String, dynamic>>(
            '/api/listings/listing-uuid-001/photos/',
            data: any(named: 'data'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenThrow(dioError(
        '/api/listings/listing-uuid-001/photos/',
        statusCode: 413,
        data: const {'detail': 'File too large'},
      ));

      final actions = container.read(photoActionsProvider);

      expect(
        () => actions.uploadPhotos('listing-uuid-001', [xfile]),
        throwsA(isA<DioException>()),
      );
    });
  });
}
