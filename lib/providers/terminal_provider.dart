import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/database/database_service.dart';
import '../data/models/server_model.dart';
import '../services/terminal_manager.dart';

class TerminalProvider extends ChangeNotifier {
  final TerminalManager _manager = TerminalManager();
  final DatabaseService _db = DatabaseService();

  double _fontSize = 14.0;
  String _themeName = 'CyberDark';
  bool _isTerminalVisible = false;
  bool _isRestored = false;

  List<TerminalSession> get sessions => _manager.sessions;
  int get activeIndex => _manager.activeSessionIndex;
  TerminalSession? get activeSession => _manager.activeSession;
  double get fontSize => _fontSize;
  String get themeName => _themeName;
  bool get isTerminalVisible => _isTerminalVisible;

  void showTerminal() {
    _isTerminalVisible = true;
    notifyListeners();
  }

  void hideTerminal() {
    _isTerminalVisible = false;
    notifyListeners();
  }

  void toggleTerminal() {
    _isTerminalVisible = !_isTerminalVisible;
    notifyListeners();
  }

  /// Restores previous open tabs in ready-to-connect state
  Future<void> restoreSavedTabs(List<ServerModel> allServers) async {
    if (_isRestored || _manager.sessions.isNotEmpty) return;
    _isRestored = true;

    try {
      final jsonStr = await _db.getSetting('last_open_tabs');
      if (jsonStr == null || jsonStr.isEmpty) return;

      final List<dynamic> serverIds = jsonDecode(jsonStr);
      for (final id in serverIds) {
        final server = allServers.cast<ServerModel?>().firstWhere(
              (s) => s?.id == id,
              orElse: () => null,
            );
        if (server != null) {
          _manager.createReadySession(
            server: server,
            onStateChanged: () => notifyListeners(),
          );
        }
      }

      if (_manager.sessions.isNotEmpty) {
        _isTerminalVisible = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring tabs: $e');
    }
  }

  /// Saves current active tabs server IDs to database
  Future<void> _saveOpenTabs() async {
    try {
      final ids = _manager.sessions.map((s) => s.server.id).toList();
      await _db.setSetting('last_open_tabs', jsonEncode(ids));
    } catch (e) {
      debugPrint('Error saving tabs: $e');
    }
  }

  /// Connects to a server and opens a new terminal tab
  Future<TerminalSession> openServerSession({
    required ServerModel server,
    required String decryptedPassword,
    required String decryptedPrivateKey,
    required String decryptedPassphrase,
  }) async {
    _isTerminalVisible = true;
    final session = await _manager.createSession(
      server: server,
      decryptedPassword: decryptedPassword,
      decryptedPrivateKey: decryptedPrivateKey,
      decryptedPassphrase: decryptedPassphrase,
      onStateChanged: () => notifyListeners(),
    );
    _saveOpenTabs();
    notifyListeners();
    return session;
  }

  /// Reconnects a specific tab in-place
  Future<void> reconnectTab({
    required int index,
    required String decryptedPassword,
    required String decryptedPrivateKey,
    required String decryptedPassphrase,
  }) async {
    if (index >= 0 && index < _manager.sessions.length) {
      final session = _manager.sessions[index];
      await _manager.reconnectSession(
        session: session,
        decryptedPassword: decryptedPassword,
        decryptedPrivateKey: decryptedPrivateKey,
        decryptedPassphrase: decryptedPassphrase,
        onStateChanged: () => notifyListeners(),
      );
      notifyListeners();
    }
  }

  void setActiveTab(int index) {
    _manager.setActiveIndex(index);
    notifyListeners();
  }

  void closeTab(int index) {
    _manager.closeSession(index, onStateChanged: () => notifyListeners());
    _saveOpenTabs();
    if (_manager.sessions.isEmpty) {
      _isTerminalVisible = false;
    }
    notifyListeners();
  }

  void closeAllTabs() {
    _manager.closeAllSessions(onStateChanged: () => notifyListeners());
    _saveOpenTabs();
    _isTerminalVisible = false;
    notifyListeners();
  }

  void sendCommand(String command) {
    _manager.sendCommandToActive(command);
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(10.0, 26.0);
    notifyListeners();
  }

  void zoomIn() {
    setFontSize(_fontSize + 1.0);
  }

  void zoomOut() {
    setFontSize(_fontSize - 1.0);
  }

  void setTheme(String theme) {
    _themeName = theme;
    notifyListeners();
  }
}
