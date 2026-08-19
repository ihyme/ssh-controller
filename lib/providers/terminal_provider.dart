import 'package:flutter/material.dart';
import '../data/models/server_model.dart';
import '../services/terminal_manager.dart';

class TerminalProvider extends ChangeNotifier {
  final TerminalManager _manager = TerminalManager();

  double _fontSize = 14.0;
  String _themeName = 'CyberDark';
  bool _isTerminalVisible = false;

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
    notifyListeners();
    return session;
  }

  void setActiveTab(int index) {
    _manager.setActiveIndex(index);
    notifyListeners();
  }

  void closeTab(int index) {
    _manager.closeSession(index, onStateChanged: () => notifyListeners());
    if (_manager.sessions.isEmpty) {
      _isTerminalVisible = false;
    }
    notifyListeners();
  }

  void closeAllTabs() {
    _manager.closeAllSessions(onStateChanged: () => notifyListeners());
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
