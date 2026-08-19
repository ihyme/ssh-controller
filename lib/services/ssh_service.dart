import 'dart:async';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

class SshConnectionResult {
  final bool success;
  final String? errorMessage;
  final SSHClient? client;
  final int? pingMs;

  SshConnectionResult({
    required this.success,
    this.errorMessage,
    this.client,
    this.pingMs,
  });
}

class SshService {
  /// Connects to a remote server using dartssh2 and returns an SSHClient
  static Future<SshConnectionResult> connect({
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKeyContent,
    String? passphrase,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: timeout,
      );

      List<SSHKeyPair>? identities;
      if (privateKeyContent != null && privateKeyContent.trim().isNotEmpty) {
        try {
          identities = SSHKeyPair.fromPem(
            privateKeyContent,
            passphrase?.isNotEmpty == true ? passphrase : null,
          );
        } catch (e) {
          socket.close();
          return SshConnectionResult(
            success: false,
            errorMessage: 'SSH Private Key çözümlenemedi: $e',
          );
        }
      }

      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password ?? '',
        identities: identities,
      );

      // Authenticate
      await client.authenticated;
      stopwatch.stop();

      return SshConnectionResult(
        success: true,
        client: client,
        pingMs: stopwatch.elapsedMilliseconds,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      return SshConnectionResult(
        success: false,
        errorMessage: 'Sunucuya ulaşılamadı (${e.osError?.message ?? e.message}). Host ve Port bilgilerini kontrol edin.',
      );
    } on TimeoutException {
      stopwatch.stop();
      return SshConnectionResult(
        success: false,
        errorMessage: 'Bağlantı zaman aşımına uğradı ($timeout sn).',
      );
    } on SSHAuthFailError {
      stopwatch.stop();
      return SshConnectionResult(
        success: false,
        errorMessage: 'Kimlik doğrulama başarısız! Kullanıcı adı, şifre veya SSH Key bilgilerinizi kontrol edin.',
      );
    } catch (e) {
      stopwatch.stop();
      return SshConnectionResult(
        success: false,
        errorMessage: 'SSH Bağlantı Hatası: $e',
      );
    }
  }

  /// Performs a quick test / ping to verify credentials without creating a full shell
  static Future<SshConnectionResult> testConnection({
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKeyContent,
    String? passphrase,
  }) async {
    final result = await connect(
      host: host,
      port: port,
      username: username,
      password: password,
      privateKeyContent: privateKeyContent,
      passphrase: passphrase,
      timeout: const Duration(seconds: 8),
    );

    if (result.success && result.client != null) {
      try {
        result.client!.close();
      } catch (_) {}
    }

    return result;
  }
}
