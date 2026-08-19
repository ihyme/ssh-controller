import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/database/database_service.dart';
import '../data/models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId; // null means 'All Servers'
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;

  CategoryModel? get selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == _selectedCategoryId);
    } catch (_) {
      return null;
    }
  }

  CategoryProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _db.getCategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<CategoryModel> addCategory({
    required String name,
    String icon = 'folder',
    String colorHex = '#10B981',
  }) async {
    const uuid = Uuid();
    final newCategory = CategoryModel(
      id: uuid.v4(),
      name: name,
      icon: icon,
      colorHex: colorHex,
      sortOrder: _categories.length,
    );

    await _db.insertCategory(newCategory);
    await loadCategories();
    return newCategory;
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _db.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.deleteCategory(categoryId);
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null;
    }
    await loadCategories();
  }
}
