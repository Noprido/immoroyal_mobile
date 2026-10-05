import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';

class SuggestionsService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, List<String>>> getSuggestions() async {
    final resp = await _dio.get(ApiConstants.suggestionsBenin);
    final data = resp.data as Map<String, dynamic>;
    return {
      'villes': List<String>.from(data['villes'] ?? []),
      'quartiers': List<String>.from(data['quartiers'] ?? []),
    };
  }
}