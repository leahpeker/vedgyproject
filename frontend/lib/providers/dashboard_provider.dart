import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/listing.dart';
import '../services/api_client.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<DashboardOut> dashboard(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.get<Map<String, dynamic>>('/api/listings/dashboard/');
  return DashboardOut.fromJson(response.data!);
}
