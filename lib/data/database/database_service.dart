import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../models/server_model.dart';
import '../models/snippet_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabaseLocation();

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await _createTables(db);
          await _seedInitialData(db);
        },
      ),
    );
  }

  /// Resolves the database path (prioritizes application directory ./data/ folder)
  Future<String> getDatabaseLocation() async {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final localDataDir = Directory(p.join(exeDir, 'data'));
      if (!await localDataDir.exists()) {
        await localDataDir.create(recursive: true);
      }
      return p.join(localDataDir.path, 'ssh_manager.db');
    } catch (_) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dbFolder = Directory(p.join(appDocDir.path, 'RoPiSSHManager'));
      if (!await dbFolder.exists()) {
        await dbFolder.create(recursive: true);
      }
      return p.join(dbFolder.path, 'ssh_manager.db');
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        color_hex TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS servers (
        id TEXT PRIMARY KEY,
        category_id TEXT,
        name TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER DEFAULT 22,
        username TEXT DEFAULT 'root',
        auth_type TEXT DEFAULT 'password',
        encrypted_password TEXT,
        encrypted_private_key TEXT,
        encrypted_passphrase TEXT,
        tags TEXT,
        notes TEXT,
        color_hex TEXT,
        is_favorite INTEGER DEFAULT 0,
        last_connected_at TEXT,
        created_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS snippets (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        command TEXT NOT NULL,
        category TEXT,
        icon TEXT,
        description TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_servers_category ON servers (category_id)');
  }

  Future<void> _seedInitialData(Database db) async {
    const uuid = Uuid();
    
    // Default categories
    final defaultCategories = [
      CategoryModel(id: uuid.v4(), name: 'Web Sunucuları', icon: 'globe', colorHex: '#10B981', sortOrder: 0),
      CategoryModel(id: uuid.v4(), name: 'Veritabanları', icon: 'database', colorHex: '#06B6D4', sortOrder: 1),
      CategoryModel(id: uuid.v4(), name: 'Docker & Kubernetes', icon: 'server', colorHex: '#6366F1', sortOrder: 2),
      CategoryModel(id: uuid.v4(), name: 'Geliştirme / Test', icon: 'code', colorHex: '#F59E0B', sortOrder: 3),
      CategoryModel(id: uuid.v4(), name: 'Üretim (Production)', icon: 'shield', colorHex: '#EF4444', sortOrder: 4),
    ];

    for (final cat in defaultCategories) {
      await db.insert('categories', cat.toMap());
    }

    // Default useful snippets
    final defaultSnippets = [
      SnippetModel(id: uuid.v4(), title: 'Kaynak Kullanımı (htop)', command: 'htop', category: 'İzleme', description: 'Canlı CPU, RAM ve süreç izleme'),
      SnippetModel(id: uuid.v4(), title: 'Disk Durumu (df -h)', command: 'df -h', category: 'Sistem', description: 'Disk doluluk oranları'),
      SnippetModel(id: uuid.v4(), title: 'Bellek Durumu (free -m)', command: 'free -m', category: 'Sistem', description: 'Kullanılabilir RAM ve Swap'),
      SnippetModel(id: uuid.v4(), title: 'Çalışan Docker Konteynerleri', command: 'docker ps', category: 'Docker', description: 'Aktif konteyner listesi'),
      SnippetModel(id: uuid.v4(), title: 'Docker Logları (Son 100 satır)', command: 'docker logs --tail 100 -f ', category: 'Docker', description: 'Konteyner canlı log akışı'),
      SnippetModel(id: uuid.v4(), title: 'Açık Portlar (netstat)', command: 'netstat -tuln', category: 'Ağ', description: 'Dinlenen portlar'),
      SnippetModel(id: uuid.v4(), title: 'Sistem Logları (syslog)', command: 'tail -f -n 50 /var/log/syslog', category: 'Loglar', description: 'Canlı syslog akışı'),
      SnippetModel(id: uuid.v4(), title: 'Nginx Servis Durumu', command: 'systemctl status nginx', category: 'Servisler', description: 'Nginx servis durumu kontrolü'),
      SnippetModel(id: uuid.v4(), title: 'Nginx Yeniden Başlat', command: 'sudo systemctl restart nginx', category: 'Servisler', description: 'Nginx servisini yeniden başlat'),
      SnippetModel(id: uuid.v4(), title: 'Sistem Güncelleme', command: 'sudo apt update && sudo apt upgrade -y', category: 'Bakım', description: 'Paket listesini ve sistemi güncelle'),
    ];

    for (final snip in defaultSnippets) {
      await db.insert('snippets', snip.toMap());
    }
  }

  // --- Category CRUD ---
  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'sort_order ASC, name ASC');
    return maps.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> insertCategory(CategoryModel category) async {
    final db = await database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await database;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- Server CRUD ---
  Future<List<ServerModel>> getServers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('servers', orderBy: 'is_favorite DESC, name ASC');
    return maps.map((e) => ServerModel.fromMap(e)).toList();
  }

  Future<void> insertServer(ServerModel server) async {
    final db = await database;
    await db.insert('servers', server.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateServer(ServerModel server) async {
    final db = await database;
    await db.update('servers', server.toMap(), where: 'id = ?', whereArgs: [server.id]);
  }

  Future<void> deleteServer(String id) async {
    final db = await database;
    await db.delete('servers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateServerLastConnected(String id) async {
    final db = await database;
    await db.update(
      'servers',
      {'last_connected_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Snippets CRUD ---
  Future<List<SnippetModel>> getSnippets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('snippets', orderBy: 'category ASC, title ASC');
    return maps.map((e) => SnippetModel.fromMap(e)).toList();
  }

  Future<void> insertSnippet(SnippetModel snippet) async {
    final db = await database;
    await db.insert('snippets', snippet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSnippet(String id) async {
    final db = await database;
    await db.delete('snippets', where: 'id = ?', whereArgs: [id]);
  }

  // --- Settings ---
  Future<String?> getSetting(String key) async {
    final db = await database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
