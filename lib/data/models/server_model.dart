import 'dart:convert';

enum SshAuthType {
  password,
  keyFile,
  keyText,
}

class ServerModel {
  final String id;
  final String? categoryId;
  final String name;
  final String host;
  final int port;
  final String username;
  final SshAuthType authType;
  final String encryptedPassword;
  final String encryptedPrivateKey;
  final String encryptedPassphrase;
  final List<String> tags;
  final String notes;
  final String colorHex;
  final bool isFavorite;
  final DateTime? lastConnectedAt;
  final DateTime createdAt;

  ServerModel({
    required this.id,
    this.categoryId,
    required this.name,
    required this.host,
    this.port = 22,
    this.username = 'root',
    this.authType = SshAuthType.password,
    this.encryptedPassword = '',
    this.encryptedPrivateKey = '',
    this.encryptedPassphrase = '',
    this.tags = const [],
    this.notes = '',
    this.colorHex = '#10B981',
    this.isFavorite = false,
    this.lastConnectedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'auth_type': authType.name,
      'encrypted_password': encryptedPassword,
      'encrypted_private_key': encryptedPrivateKey,
      'encrypted_passphrase': encryptedPassphrase,
      'tags': jsonEncode(tags),
      'notes': notes,
      'color_hex': colorHex,
      'is_favorite': isFavorite ? 1 : 0,
      'last_connected_at': lastConnectedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ServerModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null) {
      try {
        final decoded = jsonDecode(map['tags'] as String);
        if (decoded is List) {
          parsedTags = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedTags = (map['tags'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    SshAuthType parsedAuthType = SshAuthType.password;
    if (map['auth_type'] != null) {
      parsedAuthType = SshAuthType.values.firstWhere(
        (e) => e.name == map['auth_type'],
        orElse: () => SshAuthType.password,
      );
    }

    return ServerModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      name: map['name'] as String,
      host: map['host'] as String,
      port: (map['port'] as int?) ?? 22,
      username: (map['username'] as String?) ?? 'root',
      authType: parsedAuthType,
      encryptedPassword: (map['encrypted_password'] as String?) ?? '',
      encryptedPrivateKey: (map['encrypted_private_key'] as String?) ?? '',
      encryptedPassphrase: (map['encrypted_passphrase'] as String?) ?? '',
      tags: parsedTags,
      notes: (map['notes'] as String?) ?? '',
      colorHex: (map['color_hex'] as String?) ?? '#10B981',
      isFavorite: ((map['is_favorite'] as int?) ?? 0) == 1,
      lastConnectedAt: map['last_connected_at'] != null
          ? DateTime.tryParse(map['last_connected_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ServerModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? host,
    int? port,
    String? username,
    SshAuthType? authType,
    String? encryptedPassword,
    String? encryptedPrivateKey,
    String? encryptedPassphrase,
    List<String>? tags,
    String? notes,
    String? colorHex,
    bool? isFavorite,
    DateTime? lastConnectedAt,
    DateTime? createdAt,
  }) {
    return ServerModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      encryptedPrivateKey: encryptedPrivateKey ?? this.encryptedPrivateKey,
      encryptedPassphrase: encryptedPassphrase ?? this.encryptedPassphrase,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      colorHex: colorHex ?? this.colorHex,
      isFavorite: isFavorite ?? this.isFavorite,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
