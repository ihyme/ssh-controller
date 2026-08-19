import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/database_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/terminal_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final terminalProvider = context.watch<TerminalProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSidebar,
        title: const Text('Ayarlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          // Section: Security
          _buildSectionHeader('GÜVENLİK VE ŞİFRELEME', Icons.shield_outlined),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        authProvider.hasMasterPassword ? Icons.lock_rounded : Icons.lock_open_rounded,
                        color: authProvider.hasMasterPassword ? AppColors.primary : AppColors.accentAmber,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.hasMasterPassword
                                  ? 'Ana Parola Koruması (Master Password) Aktif'
                                  : 'Ana Parola Tanımlı Değil',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authProvider.hasMasterPassword
                                  ? 'Tüm sunucu şifreleriniz ve SSH anahtarlarınız AES-256 ile ana parolanızdan türetilen anahtar ile korunuyor.'
                                  : 'Verileriniz cihazınıza özel donanım anahtarı ile şifreleniyor. Ekstra güvenlik için ana parola oluşturabilirsiniz.',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _showMasterPasswordDialog(context, authProvider),
                        child: Text(authProvider.hasMasterPassword ? 'Parolayı Değiştir' : 'Ana Parola Oluştur'),
                      ),
                      if (authProvider.hasMasterPassword) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _confirmRemoveMasterPassword(context, authProvider),
                          child: const Text('Kaldır', style: TextStyle(color: AppColors.statusError)),
                        ),
                      ],
                    ],
                  ),

                  if (authProvider.hasMasterPassword) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 20, color: AppColors.textMuted),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Hareketsizlik Sonrası Otomatik Kilitleme',
                            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                        DropdownButton<int>(
                          value: authProvider.autoLockMinutes,
                          dropdownColor: AppColors.darkCard,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 Dakika')),
                            DropdownMenuItem(value: 5, child: Text('5 Dakika')),
                            DropdownMenuItem(value: 15, child: Text('15 Dakika')),
                            DropdownMenuItem(value: 30, child: Text('30 Dakika')),
                            DropdownMenuItem(value: 60, child: Text('1 Saat')),
                            DropdownMenuItem(value: 0, child: Text('Asla')),
                          ],
                          onChanged: (val) {
                            if (val != null) authProvider.setAutoLockTimeout(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section: Terminal Preferences
          _buildSectionHeader('TERMINAL TERCİHLERİ', Icons.terminal_rounded),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.format_size_rounded, size: 20, color: AppColors.textMuted),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Yazı Tipi Boyutu (Font Size)',
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        '${terminalProvider.fontSize.toInt()} px',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 180,
                        child: Slider(
                          value: terminalProvider.fontSize,
                          min: 10,
                          max: 24,
                          divisions: 14,
                          activeColor: AppColors.primary,
                          onChanged: (val) => terminalProvider.setFontSize(val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section: Backup & Restore
          _buildSectionHeader('YEDEKLEME VE GERİ YÜKLEME', Icons.backup_outlined),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.download_rounded, size: 20, color: AppColors.accentCyan),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Şifreli Yedek Dışa Aktar (.json)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            SizedBox(height: 2),
                            Text('Tüm sunucularınızı ve kategorilerinizi şifrelenmiş dosya olarak indirin.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('Yedek Al'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCyan),
                        onPressed: () => _exportBackup(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.upload_rounded, size: 20, color: AppColors.accentIndigo),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Yedekten Geri Yükle (.json)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            SizedBox(height: 2),
                            Text('Daha önce aldığınız yedek dosyasını içeri aktarın.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                        label: const Text('İçe Aktar'),
                        onPressed: () => _importBackup(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 14),
                  FutureBuilder<String>(
                    future: DatabaseService().getDatabaseLocation(),
                    builder: (context, snapshot) {
                      final path = snapshot.data ?? 'Yükleniyor...';
                      return Row(
                        children: [
                          const Icon(Icons.storage_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Aktif Veritabanı Konumu (Taşınabilir / Yerel)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                SelectableText(
                                  path,
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: AppColors.accentAmber),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Güvenlik Notu: Veritabanını farklı bilgisayarlara taşırken her zaman bir Ana Parola (Master Password) kullanmanız önerilir. Bu sayede veritabanı dosyanız yolda başkalarının eline geçse bile Ana Parolanız olmadan asla içeriği okunamaz.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section: About
          _buildSectionHeader('UYGULAMA HAKKINDA', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accentCyan]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.terminal_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RoPi SSH Manager Pro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      SizedBox(height: 2),
                      Text('RoPi LLC • macOS, Windows ve Linux Uyumlu', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      SizedBox(height: 2),
                      Text('AES-256 & SQLite Güvenli Veritabanı Mimarisi', style: TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
        ),
      ],
    );
  }

  void _showMasterPasswordDialog(BuildContext context, AuthProvider auth) {
    final passController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(auth.hasMasterPassword ? 'Ana Parolayı Güncelle' : 'Ana Parola Belirle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu parola uygulamayı açarken istenecektir ve SQLite veritabanındaki tüm sunucu kimlik bilgilerinizi şifrelemek için kullanılacaktır.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni Ana Parola', hintText: '••••••••'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Parolayı Tekrar Girin', hintText: '••••••••'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (passController.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parola en az 4 karakter olmalıdır.')));
                return;
              }
              if (passController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parolalar eşleşmiyor!')));
                return;
              }

              await auth.setMasterPassword(passController.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ana parola başarıyla kaydedildi.')));
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMasterPassword(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ana Parola Kaldırılsın mı?'),
        content: const Text('Ana parola kaldırıldığında verileriniz sadece bu cihaza özel otomatik donanım anahtarı ile şifreli kalacaktır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusError),
            onPressed: () async {
              await auth.removeMasterPassword();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final serverProvider = context.read<ServerProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    try {
      final exportData = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'categories': categoryProvider.categories.map((c) => c.toMap()).toList(),
        'servers': serverProvider.servers.map((s) => s.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Yedek Dosyasını Kaydet',
        fileName: 'ropi_ssh_backup_$dateStr.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonString);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Yedek başarıyla kaydedildi: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedek alma hatası: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final serverProvider = context.read<ServerProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Yedek Dosyası Seç (.json)',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        if (data.containsKey('categories') && data['categories'] is List) {
          for (final catMap in data['categories']) {
            try {
              await categoryProvider.addCategory(
                name: catMap['name'],
                icon: catMap['icon'] ?? 'folder',
                colorHex: catMap['color_hex'] ?? '#10B981',
              );
            } catch (_) {}
          }
        }

        if (data.containsKey('servers') && data['servers'] is List) {
          for (final sMap in data['servers']) {
            try {
              await serverProvider.addServer(
                name: sMap['name'],
                host: sMap['host'],
                port: sMap['port'] ?? 22,
                username: sMap['username'] ?? 'root',
                categoryId: sMap['category_id'],
                notes: sMap['notes'] ?? '',
                colorHex: sMap['color_hex'] ?? '#10B981',
              );
            } catch (_) {}
          }
        }

        await serverProvider.loadServers();
        await categoryProvider.loadCategories();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yedek başarıyla içe aktarıldı!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İçe aktarma hatası: $e')),
        );
      }
    }
  }
}
