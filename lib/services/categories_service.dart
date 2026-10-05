import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/category.dart';

class CategoriesService {
  final Dio _dio = DioClient.instance;

  Future<List<CategoryModel>> getCategories() async {
    final resp = await _dio.get(ApiConstants.categories);
    final list = resp.data as List;
    return list.map((j) => CategoryModel.fromJson(j as Map<String, dynamic>)).toList();
  }
}