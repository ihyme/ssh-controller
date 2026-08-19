import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
  );

  static const String _keyMasterHash = 'ssh_mgr_master_hash';
  static const String _keyMasterSalt = 'ssh_mgr_master_salt';
  static const String _keyDeviceEncryptionKey = 'ssh_mgr_device_enc_key';
  static const String _keyAutoLockMinutes = 'ssh_mgr_autolock_mins';
  static const String _keyRequireMasterPass = 'ssh_mgr_require_master_pass';

  /// Returns true if a master password has been set by the user
  Future<bool> hasMasterPassword() async {
    try {
      final hash = await _storage.read(key: _keyMasterHash);
      final requirePass = await _storage.read(key: _keyRequireMasterPass);
      return hash != null && hash.isNotEmpty && (requirePass != 'false');
    } catch (_) {
      return false;
    }
  }

  /// Sets or updates the master password and salt
  Future<void> saveMasterPassword(String passwordHash, String salt) async {
    await _storage.write(key: _keyMasterHash, value: passwordHash);
    await _storage.write(key: _keyMasterSalt, value: salt);
    await _storage.write(key: _keyRequireMasterPass, value: 'true');
  }

  /// Disables master password requirement (uses device hardware key instead)
  Future<void> disableMasterPassword() async {
    await _storage.write(key: _keyRequireMasterPass, value: 'false');
  }

  Future<String?> getMasterHash() async {
    return await _storage.read(key: _keyMasterHash);
  }

  Future<String?> getMasterSalt() async {
    return await _storage.read(key: _keyMasterSalt);
  }

  /// Gets or generates a fallback device encryption key (so database is always encrypted even without master password)
  Future<String> getOrCreateDeviceKey() async {
    try {
      var key = await _storage.read(key: _keyDeviceEncryptionKey);
      if (key == null || key.isEmpty) {
        key = const Uuid().v4() + const Uuid().v4();
        await _storage.write(key: _keyDeviceEncryptionKey, value: key);
      }
      return key;
    } catch (e) {
      // Fallback if secure storage encounters OS permission issue
      return 'ROPI_FALLBACK_DEVICE_KEY_${Platform.operatingSystem}_SECURE';
    }
  }

  Future<int> getAutoLockMinutes() async {
    final val = await _storage.read(key: _keyAutoLockMinutes);
    return val != null ? int.tryParse(val) ?? 15 : 15;
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    await _storage.write(key: _keyAutoLockMinutes, value: minutes.toString());
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
