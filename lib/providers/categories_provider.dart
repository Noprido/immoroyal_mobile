import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/categories_service.dart';
import '../core/constants/app_config.dart';
import '../core/cache/cache_service.dart';

class CategoriesProvider extends ChangeNotifier {
  final CategoriesService _service = CategoriesService();

  List<CategoryModel> _categories = [];
  bool _loading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  bool                 get loading    => _loading;
  String?              get error      => _error;

  CategoryModel? byValue(String value) {
    try {
      return _categories.firstWhere((c) => c.value == value);
    } catch (_) {
      return null;
    }
  }

  Future<void> load({bool silent = false}) async {
    if (!silent && AppConfig.persistanceActive) {
      final cached = CacheService.read(AppConfig.hiveBoxCategories, AppConfig.keyCategories);
      if (cached != null) {
        _categories = cached.map((j) => CategoryModel.fromJson(j)).toList();
        _loading = false;
        notifyListeners();
        silent = true;
      }
    }

    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final result = await _service.getCategories();
      _categories = result;

      if (AppConfig.persistanceActive) {
        await CacheService.save(
          AppConfig.hiveBoxCategories,
          AppConfig.keyCategories,
          result.map((c) => c.toJson()).toList(),
        );
      }
    } catch (_) {
      if (_categories.isEmpty) _error = 'Erreur de chargement.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}