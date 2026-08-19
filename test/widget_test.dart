import 'package:flutter_test/flutter_test.dart';
import 'package:ssh_yonetim/core/security/encryption_service.dart';
import 'package:ssh_yonetim/data/models/category_model.dart';
import 'package:ssh_yonetim/data/models/server_model.dart';

void main() {
  group('EncryptionService Tests', () {
    test('AES-256 Encryption and Decryption works properly', () {
      final encryption = EncryptionService();
      encryption.initializeKey('MyMasterSecretPassword123!', salt: 'test_salt');

      const plainSecret = 'super_secret_ssh_password_or_private_key_content';
      final encrypted = encryption.encrypt(plainSecret);

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plainSecret)));
      expect(encrypted.contains(':'), isTrue);

      final decrypted = encryption.decrypt(encrypted);
      expect(decrypted, equals(plainSecret));
    });

    test('Password Hashing with Salt produces consistent hash', () {
      const password = 'StrongPassword99!';
      const salt = 'random_salt_123';

      final hash1 = EncryptionService.hashPassword(password, salt);
      final hash2 = EncryptionService.hashPassword(password, salt);
      final hash3 = EncryptionService.hashPassword('WrongPassword', salt);

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
    });
  });

  group('Model Serialization Tests', () {
    test('ServerModel serializes and deserializes correctly', () {
      final server = ServerModel(
        id: 'test-uuid-1',
        name: 'Production Web 01',
        host: '192.168.1.10',
        port: 2222,
        username: 'deploy',
        authType: SshAuthType.keyFile,
        encryptedPassword: 'enc_password_abc',
        tags: ['web', 'prod', 'nginx'],
        notes: 'Main web server',
        isFavorite: true,
      );

      final map = server.toMap();
      final restored = ServerModel.fromMap(map);

      expect(restored.id, equals(server.id));
      expect(restored.name, equals(server.name));
      expect(restored.host, equals(server.host));
      expect(restored.port, equals(2222));
      expect(restored.authType, equals(SshAuthType.keyFile));
      expect(restored.tags, equals(['web', 'prod', 'nginx']));
      expect(restored.isFavorite, isTrue);
    });

    test('CategoryModel serializes and deserializes correctly', () {
      final category = CategoryModel(
        id: 'cat-1',
        name: 'Veritabanları',
        icon: 'database',
        colorHex: '#06B6D4',
        sortOrder: 2,
      );

      final map = category.toMap();
      final restored = CategoryModel.fromMap(map);

      expect(restored.id, equals(category.id));
      expect(restored.name, equals('Veritabanları'));
      expect(restored.icon, equals('database'));
      expect(restored.colorHex, equals('#06B6D4'));
      expect(restored.sortOrder, equals(2));
    });
  });
}
