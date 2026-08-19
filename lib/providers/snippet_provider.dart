import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/database/database_service.dart';
import '../data/models/snippet_model.dart';

class SnippetProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<SnippetModel> _snippets = [];
  bool _isLoading = false;

  List<SnippetModel> get snippets => _snippets;
  bool get isLoading => _isLoading;

  SnippetProvider() {
    loadSnippets();
  }

  Future<void> loadSnippets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _snippets = await _db.getSnippets();
    } catch (e) {
      debugPrint('Error loading snippets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> get categories {
    final set = <String>{'Tümü'};
    for (final s in _snippets) {
      set.add(s.category);
    }
    return set.toList();
  }

  Future<void> addSnippet({
    required String title,
    required String command,
    String category = 'Genel',
    String description = '',
  }) async {
    const uuid = Uuid();
    final snippet = SnippetModel(
      id: uuid.v4(),
      title: title,
      command: command,
      category: category,
      description: description,
    );

    await _db.insertSnippet(snippet);
    await loadSnippets();
  }

  Future<void> deleteSnippet(String id) async {
    await _db.deleteSnippet(id);
    await loadSnippets();
  }
}
