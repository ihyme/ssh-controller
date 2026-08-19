import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/security/encryption_service.dart';
import '../core/security/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  final EncryptionService _encryption = EncryptionService();

  bool _isUnlocked = false;
  bool _hasMasterPassword = false;
  bool _isLoading = true;
  int _autoLockMinutes = 15;
  Timer? _autoLockTimer;

  bool get isUnlocked => _isUnlocked;
  bool get hasMasterPassword => _hasMasterPassword;
  bool get isLoading => _isLoading;
  int get autoLockMinutes => _autoLockMinutes;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _hasMasterPassword = await _storage.hasMasterPassword();
    _autoLockMinutes = await _storage.getAutoLockMinutes();

    if (!_hasMasterPassword) {
      // Auto-unlock using device hardware encryption key
      final deviceKey = await _storage.getOrCreateDeviceKey();
      _encryption.initializeKey(deviceKey);
      _isUnlocked = true;
    } else {
      _isUnlocked = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Attempts to unlock the app using user entered Master Password
  Future<bool> unlockWithPassword(String password) async {
    final salt = await _storage.getMasterSalt();
    final savedHash = await _storage.getMasterHash();

    if (salt == null || savedHash == null) {
      // No password was configured, initialize with device key
      final deviceKey = await _storage.getOrCreateDeviceKey();
      _encryption.initializeKey(deviceKey);
      _isUnlocked = true;
      _resetAutoLockTimer();
      notifyListeners();
      return true;
    }

    final inputHash = EncryptionService.hashPassword(password, salt);
    if (inputHash == savedHash) {
      _encryption.initializeKey(password, salt: salt);
      _isUnlocked = true;
      _resetAutoLockTimer();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  /// Sets or updates Master Password
  Future<void> setMasterPassword(String newPassword) async {
    final salt = EncryptionService.generateRandomSalt(32);
    final hash = EncryptionService.hashPassword(newPassword, salt);

    await _storage.saveMasterPassword(hash, salt);
    _encryption.initializeKey(newPassword, salt: salt);
    _hasMasterPassword = true;
    _isUnlocked = true;
    _resetAutoLockTimer();
    notifyListeners();
  }

  /// Removes Master Password requirement and switches to device encryption key
  Future<void> removeMasterPassword() async {
    await _storage.disableMasterPassword();
    final deviceKey = await _storage.getOrCreateDeviceKey();
    _encryption.initializeKey(deviceKey);
    _hasMasterPassword = false;
    _isUnlocked = true;
    _cancelAutoLockTimer();
    notifyListeners();
  }

  /// Manually locks the app
  void lock() {
    if (_hasMasterPassword) {
      _isUnlocked = false;
      _cancelAutoLockTimer();
      notifyListeners();
    }
  }

  void reportUserActivity() {
    if (_hasMasterPassword && _isUnlocked) {
      _resetAutoLockTimer();
    }
  }

  void setAutoLockTimeout(int minutes) async {
    _autoLockMinutes = minutes;
    await _storage.setAutoLockMinutes(minutes);
    _resetAutoLockTimer();
    notifyListeners();
  }

  void _resetAutoLockTimer() {
    _cancelAutoLockTimer();
    if (_autoLockMinutes > 0 && _hasMasterPassword) {
      _autoLockTimer = Timer(Duration(minutes: _autoLockMinutes), () {
        lock();
      });
    }
  }

  void _cancelAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  @override
  void dispose() {
    _cancelAutoLockTimer();
    super.dispose();
  }
}
