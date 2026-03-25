import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> okResponse(
  Map<String, dynamic> data,
  String path,
) => Response<Map<String, dynamic>>(
  data: data,
  statusCode: 200,
  requestOptions: RequestOptions(path: path),
);

DioException dioError(
  String path, {
  int statusCode = 401,
  Map<String, dynamic> data = const {'detail': 'Authentication failed.'},
}) => DioException(
  requestOptions: RequestOptions(path: path),
  response: Response(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: path),
  ),
  type: DioExceptionType.badResponse,
);
