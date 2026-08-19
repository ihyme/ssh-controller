import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  enc.Key? _activeKey;

  /// Sets the active encryption key derived from Master Password or Hardware Key
  void initializeKey(String masterKeyOrPin, {String salt = 'ROPI_SSH_DEFAULT_SALT_2026'}) {
    final keyBytes = _deriveKeyBytes(masterKeyOrPin, salt);
    _activeKey = enc.Key(keyBytes);
  }

  bool get isKeyInitialized => _activeKey != null;

  /// Derives a 256-bit key from input password + salt using SHA-256 iterations
  Uint8List _deriveKeyBytes(String password, String salt) {
    List<int> bytes = utf8.encode('$password::$salt');
    // PBKDF2-style key stretching
    for (int i = 0; i < 5000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return Uint8List.fromList(bytes);
  }

  /// Encrypts plain text with AES-CBC-PKCS7 and prepends random 16-byte IV
  String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    if (_activeKey == null) {
      throw StateError('Şifreleme anahtarı henüz yüklenmedi (Master Key not initialized).');
    }

    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_activeKey!, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Format: base64(IV):base64(Ciphertext)
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts ciphertext formatted as base64(IV):base64(Ciphertext)
  String decrypt(String cipherText) {
    if (cipherText.isEmpty) return '';
    if (_activeKey == null) {
      throw StateError('Şifreleme anahtarı henüz yüklenmedi (Master Key not initialized).');
    }

    try {
      final parts = cipherText.split(':');
      if (parts.length != 2) {
        // Fallback if plain text was stored somehow
        return cipherText;
      }

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedData = enc.Encrypted.fromBase64(parts[1]);
      final encrypter = enc.Encrypter(enc.AES(_activeKey!, mode: enc.AESMode.cbc));

      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      // Return empty or error indicator if corrupted / wrong master key
      return '';
    }
  }

  /// Hashes a password with salt for verification
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password::$salt');
    var hash = sha256.convert(bytes);
    for (int i = 0; i < 5000; i++) {
      hash = sha256.convert(hash.bytes);
    }
    return hash.toString();
  }

  /// Generates a random secure salt
  static String generateRandomSalt([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}
