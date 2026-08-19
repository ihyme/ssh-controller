import 'dart:io';

class ExternalTerminalService {
  /// Opens the native system terminal and initiates SSH connection
  static Future<bool> launch({
    required String host,
    required int port,
    required String username,
  }) async {
    final sshArgs = '$username@$host -p $port';

    try {
      if (Platform.isWindows) {
        // Try Windows Terminal (wt.exe) first, fallback to PowerShell
        try {
          await Process.start('wt.exe', ['ssh', '$username@$host', '-p', port.toString()]);
          return true;
        } catch (_) {
          await Process.start('cmd.exe', ['/c', 'start', 'powershell', '-NoExit', '-Command', 'ssh $sshArgs']);
          return true;
        }
      } else if (Platform.isMacOS) {
        // macOS AppleScript to open Terminal.app
        await Process.run('osascript', [
          '-e',
          'tell application "Terminal" to do script "ssh $sshArgs"',
          '-e',
          'tell application "Terminal" to activate',
        ]);
        return true;
      } else if (Platform.isLinux) {
        // Try gnome-terminal, konsole, xfce4-terminal, or xterm
        final terminals = ['gnome-terminal', 'konsole', 'xfce4-terminal', 'xterm'];
        for (final term in terminals) {
          try {
            if (term == 'gnome-terminal') {
              await Process.start(term, ['--', 'ssh', '$username@$host', '-p', port.toString()]);
            } else {
              await Process.start(term, ['-e', 'ssh $sshArgs']);
            }
            return true;
          } catch (_) {
            continue;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
