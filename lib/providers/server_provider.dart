import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/security/encryption_service.dart';
import '../data/database/database_service.dart';
import '../data/models/server_model.dart';
import '../services/ssh_service.dart';

class DecryptedCredentials {
  final String password;
  final String privateKey;
  final String passphrase;

  DecryptedCredentials({
    required this.password,
    required this.privateKey,
    required this.passphrase,
  });
}

class ServerProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final EncryptionService _encryption = EncryptionService();

  List<ServerModel> _servers = [];
  String _searchQuery = '';
  String? _selectedTag;
  bool _favoritesOnly = false;
  bool _isLoading = false;
  final Map<String, int?> _serverLatencies = {};

  List<ServerModel> get servers => _servers;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;
  bool get favoritesOnly => _favoritesOnly;
  bool get isLoading => _isLoading;
  Map<String, int?> get serverLatencies => _serverLatencies;

  ServerProvider() {
    loadServers();
  }

  Future<void> loadServers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _servers = await _db.getServers();
    } catch (e) {
      debugPrint('Error loading servers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ServerModel> getFilteredServers({String? categoryId}) {
    return _servers.where((server) {
      // Category filter
      if (categoryId != null && server.categoryId != categoryId) {
        return false;
      }

      // Favorites filter
      if (_favoritesOnly && !server.isFavorite) {
        return false;
      }

      // Tag filter
      if (_selectedTag != null && !server.tags.contains(_selectedTag)) {
        return false;
      }

      // Search query filter (Name, Host, Port, Username, Notes, Tags)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = server.name.toLowerCase().contains(query);
        final matchesHost = server.host.toLowerCase().contains(query);
        final matchesUser = server.username.toLowerCase().contains(query);
        final matchesNotes = server.notes.toLowerCase().contains(query);
        final matchesPort = server.port.toString().contains(query);
        final matchesTags = server.tags.any((t) => t.toLowerCase().contains(query));

        if (!matchesName && !matchesHost && !matchesUser && !matchesNotes && !matchesPort && !matchesTags) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Set<String> get allTags {
    final tags = <String>{};
    for (final server in _servers) {
      tags.addAll(server.tags);
    }
    return tags;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
  }

  /// Adds a new server with encrypted credentials
  Future<ServerModel> addServer({
    required String name,
    required String host,
    int port = 22,
    required String username,
    String? categoryId,
    SshAuthType authType = SshAuthType.password,
    String plainPassword = '',
    String plainPrivateKey = '',
    String plainPassphrase = '',
    List<String> tags = const [],
    String notes = '',
    String colorHex = '#10B981',
  }) async {
    const uuid = Uuid();
    final encryptedPassword = plainPassword.isNotEmpty ? _encryption.encrypt(plainPassword) : '';
    final encryptedPrivateKey = plainPrivateKey.isNotEmpty ? _encryption.encrypt(plainPrivateKey) : '';
    final encryptedPassphrase = plainPassphrase.isNotEmpty ? _encryption.encrypt(plainPassphrase) : '';

    final server = ServerModel(
      id: uuid.v4(),
      categoryId: categoryId,
      name: name,
      host: host,
      port: port,
      username: username,
      authType: authType,
      encryptedPassword: encryptedPassword,
      encryptedPrivateKey: encryptedPrivateKey,
      encryptedPassphrase: encryptedPassphrase,
      tags: tags,
      notes: notes,
      colorHex: colorHex,
    );

    await _db.insertServer(server);
    await loadServers();
    return server;
  }

  /// Updates an existing server with encrypted credentials
  Future<void> updateServer({
    required ServerModel existingServer,
    required String name,
    required String host,
    required int port,
    required String username,
    String? categoryId,
    required SshAuthType authType,
    String? plainPassword,
    String? plainPrivateKey,
    String? plainPassphrase,
    required List<String> tags,
    required String notes,
    required String colorHex,
  }) async {
    String encryptedPassword = existingServer.encryptedPassword;
    if (plainPassword != null) {
      encryptedPassword = plainPassword.isNotEmpty ? _encryption.encrypt(plainPassword) : '';
    }

    String encryptedPrivateKey = existingServer.encryptedPrivateKey;
    if (plainPrivateKey != null) {
      encryptedPrivateKey = plainPrivateKey.isNotEmpty ? _encryption.encrypt(plainPrivateKey) : '';
    }

    String encryptedPassphrase = existingServer.encryptedPassphrase;
    if (plainPassphrase != null) {
      encryptedPassphrase = plainPassphrase.isNotEmpty ? _encryption.encrypt(plainPassphrase) : '';
    }

    final updated = existingServer.copyWith(
      categoryId: categoryId,
      name: name,
      host: host,
      port: port,
      username: username,
      authType: authType,
      encryptedPassword: encryptedPassword,
      encryptedPrivateKey: encryptedPrivateKey,
      encryptedPassphrase: encryptedPassphrase,
      tags: tags,
      notes: notes,
      colorHex: colorHex,
    );

    await _db.updateServer(updated);
    await loadServers();
  }

  Future<void> deleteServer(String id) async {
    await _db.deleteServer(id);
    _serverLatencies.remove(id);
    await loadServers();
  }

  Future<void> toggleFavorite(ServerModel server) async {
    final updated = server.copyWith(isFavorite: !server.isFavorite);
    await _db.updateServer(updated);
    await loadServers();
  }

  Future<void> markConnected(String id) async {
    await _db.updateServerLastConnected(id);
    await loadServers();
  }

  /// Decrypts credentials for connecting or editing
  DecryptedCredentials decryptCredentials(ServerModel server) {
    final password = server.encryptedPassword.isNotEmpty ? _encryption.decrypt(server.encryptedPassword) : '';
    final privateKey = server.encryptedPrivateKey.isNotEmpty ? _encryption.decrypt(server.encryptedPrivateKey) : '';
    final passphrase = server.encryptedPassphrase.isNotEmpty ? _encryption.decrypt(server.encryptedPassphrase) : '';

    return DecryptedCredentials(
      password: password,
      privateKey: privateKey,
      passphrase: passphrase,
    );
  }

  /// Pings server to test connectivity
  Future<void> pingServer(ServerModel server) async {
    final creds = decryptCredentials(server);
    final result = await SshService.testConnection(
      host: server.host,
      port: server.port,
      username: server.username,
      password: creds.password.isNotEmpty ? creds.password : null,
      privateKeyContent: creds.privateKey.isNotEmpty ? creds.privateKey : null,
      passphrase: creds.passphrase.isNotEmpty ? creds.passphrase : null,
    );

    if (result.success) {
      _serverLatencies[server.id] = result.pingMs ?? 1;
    } else {
      _serverLatencies[server.id] = -1; // Indicates error
    }
    notifyListeners();
  }
}
