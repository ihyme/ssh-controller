import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:xterm/xterm.dart';
import '../data/models/server_model.dart';
import 'ssh_service.dart';

enum TerminalSessionStatus {
  connecting,
  connected,
  disconnected,
  error,
}

class TerminalSession {
  final String id;
  final ServerModel server;
  final String title;
  final Terminal terminal;
  
  SSHClient? client;
  SSHSession? sshSession;
  TerminalSessionStatus status = TerminalSessionStatus.connecting;
  String? errorMessage;
  DateTime? connectedAt;
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;

  TerminalSession({
    required this.id,
    required this.server,
    required this.title,
    required this.terminal,
  });

  void dispose() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    try {
      sshSession?.close();
    } catch (_) {}
    try {
      client?.close();
    } catch (_) {}
  }
}

class TerminalManager {
  static final TerminalManager _instance = TerminalManager._internal();
  factory TerminalManager() => _instance;
  TerminalManager._internal();

  final List<TerminalSession> _sessions = [];
  int _activeSessionIndex = 0;

  List<TerminalSession> get sessions => List.unmodifiable(_sessions);
  int get activeSessionIndex => _activeSessionIndex;

  TerminalSession? get activeSession =>
      _sessions.isNotEmpty && _activeSessionIndex >= 0 && _activeSessionIndex < _sessions.length
          ? _sessions[_activeSessionIndex]
          : null;

  /// Creates a new terminal tab and connects to the SSH server
  Future<TerminalSession> createSession({
    required ServerModel server,
    required String decryptedPassword,
    required String decryptedPrivateKey,
    required String decryptedPassphrase,
    Function()? onStateChanged,
  }) async {
    const uuid = Uuid();
    final sessionId = uuid.v4();

    final terminal = Terminal(
      maxLines: 10000,
    );

    final title = '${server.name} (${server.username}@${server.host})';

    final session = TerminalSession(
      id: sessionId,
      server: server,
      title: title,
      terminal: terminal,
    );

    _sessions.add(session);
    _activeSessionIndex = _sessions.length - 1;
    onStateChanged?.call();

    // Start connection
    _connectSession(
      session: session,
      decryptedPassword: decryptedPassword,
      decryptedPrivateKey: decryptedPrivateKey,
      decryptedPassphrase: decryptedPassphrase,
      onStateChanged: onStateChanged,
    );

    return session;
  }

  Future<void> _connectSession({
    required TerminalSession session,
    required String decryptedPassword,
    required String decryptedPrivateKey,
    required String decryptedPassphrase,
    Function()? onStateChanged,
  }) async {
    final terminal = session.terminal;
    terminal.write('\x1b[36m⚡ [RoPi SSH] Bağlanılıyor: ${session.server.host}:${session.server.port}...\x1b[0m\r\n');

    final result = await SshService.connect(
      host: session.server.host,
      port: session.server.port,
      username: session.server.username,
      password: decryptedPassword.isNotEmpty ? decryptedPassword : null,
      privateKeyContent: decryptedPrivateKey.isNotEmpty ? decryptedPrivateKey : null,
      passphrase: decryptedPassphrase.isNotEmpty ? decryptedPassphrase : null,
    );

    if (!result.success || result.client == null) {
      session.status = TerminalSessionStatus.error;
      session.errorMessage = result.errorMessage;
      terminal.write('\x1b[31m✖ Bağlantı Başarısız: ${result.errorMessage}\x1b[0m\r\n');
      onStateChanged?.call();
      return;
    }

    try {
      session.client = result.client;
      session.status = TerminalSessionStatus.connected;
      session.connectedAt = DateTime.now();

      terminal.write('\x1b[32m✔ Bağlantı kuruldu (${result.pingMs} ms). Kabuk (Shell) başlatılıyor...\x1b[0m\r\n\r\n');
      onStateChanged?.call();

      final shell = await session.client!.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth > 0 ? terminal.viewWidth : 80,
          height: terminal.viewHeight > 0 ? terminal.viewHeight : 24,
        ),
      );
      session.sshSession = shell;

      // Handle terminal resize events
      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        shell.resizeTerminal(width, height, pixelWidth, pixelHeight);
      };

      // Handle terminal keystroke input
      terminal.onOutput = (data) {
        try {
          shell.write(utf8.encode(data));
        } catch (_) {}
      };

      // Forward stdout to terminal
      session._stdoutSub = shell.stdout.listen(
        (Uint8List data) {
          terminal.write(utf8.decode(data, allowMalformed: true));
        },
        onError: (e) {
          terminal.write('\r\n\x1b[31m[Stdout Error]: $e\x1b[0m\r\n');
        },
        onDone: () {
          session.status = TerminalSessionStatus.disconnected;
          terminal.write('\r\n\x1b[33m⚡ Oturum sonlandırıldı (Connection closed).\x1b[0m\r\n');
          onStateChanged?.call();
        },
      );

      // Forward stderr to terminal
      session._stderrSub = shell.stderr.listen(
        (Uint8List data) {
          terminal.write(utf8.decode(data, allowMalformed: true));
        },
        onError: (e) {
          terminal.write('\r\n\x1b[31m[Stderr Error]: $e\x1b[0m\r\n');
        },
      );

      onStateChanged?.call();
    } catch (e) {
      session.status = TerminalSessionStatus.error;
      session.errorMessage = e.toString();
      terminal.write('\x1b[31m✖ Kabuk başlatma hatası: $e\x1b[0m\r\n');
      onStateChanged?.call();
    }
  }

  void setActiveIndex(int index) {
    if (index >= 0 && index < _sessions.length) {
      _activeSessionIndex = index;
    }
  }

  void closeSession(int index, {Function()? onStateChanged}) {
    if (index >= 0 && index < _sessions.length) {
      final session = _sessions.removeAt(index);
      session.dispose();

      if (_activeSessionIndex >= _sessions.length) {
        _activeSessionIndex = _sessions.length - 1;
      }
      if (_activeSessionIndex < 0) {
        _activeSessionIndex = 0;
      }
      onStateChanged?.call();
    }
  }

  void closeAllSessions({Function()? onStateChanged}) {
    for (final session in _sessions) {
      session.dispose();
    }
    _sessions.clear();
    _activeSessionIndex = 0;
    onStateChanged?.call();
  }

  /// Sends a raw command string to the active terminal session
  void sendCommandToActive(String command) {
    final session = activeSession;
    if (session != null && session.sshSession != null) {
      final cmdWithNewline = command.endsWith('\n') ? command : '$command\n';
      session.sshSession!.write(utf8.encode(cmdWithNewline));
    }
  }
}
