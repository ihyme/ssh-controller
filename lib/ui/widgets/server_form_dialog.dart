import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/server_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/server_provider.dart';
import '../../services/ssh_service.dart';

class ServerFormDialog extends StatefulWidget {
  final ServerModel? server; // If not null, edit mode

  const ServerFormDialog({
    super.key,
    this.server,
  });

  @override
  State<ServerFormDialog> createState() => _ServerFormDialogState();
}

class _ServerFormDialogState extends State<ServerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _keyContentController;
  late TextEditingController _passphraseController;
  late TextEditingController _tagsController;
  late TextEditingController _notesController;

  String? _selectedCategoryId;
  SshAuthType _authType = SshAuthType.password;
  String _selectedColorHex = '#10B981';
  bool _obscurePassword = true;
  bool _obscurePassphrase = true;
  String? _pickedKeyFilePath;

  bool _isTesting = false;
  String? _testResultText;
  bool? _testResultSuccess;

  @override
  void initState() {
    super.initState();
    final s = widget.server;
    final serverProvider = context.read<ServerProvider>();

    String decryptedPass = '';
    String decryptedKey = '';
    String decryptedPassphrase = '';

    if (s != null) {
      final creds = serverProvider.decryptCredentials(s);
      decryptedPass = creds.password;
      decryptedKey = creds.privateKey;
      decryptedPassphrase = creds.passphrase;
    }

    _nameController = TextEditingController(text: s?.name ?? '');
    _hostController = TextEditingController(text: s?.host ?? '');
    _portController = TextEditingController(text: (s?.port ?? 22).toString());
    _usernameController = TextEditingController(text: s?.username ?? 'root');
    _passwordController = TextEditingController(text: decryptedPass);
    _keyContentController = TextEditingController(text: decryptedKey);
    _passphraseController = TextEditingController(text: decryptedPassphrase);
    _tagsController = TextEditingController(text: s?.tags.join(', ') ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');

    _selectedCategoryId = s?.categoryId;
    _authType = s?.authType ?? SshAuthType.password;
    _selectedColorHex = s?.colorHex ?? '#10B981';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _keyContentController.dispose();
    _passphraseController.dispose();
    _tagsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickKeyFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'SSH Private Key Dosyası Seç (id_rsa, id_ed25519 vb.)',
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final content = await file.readAsString();
        setState(() {
          _pickedKeyFilePath = result.files.single.path;
          _keyContentController.text = content;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dosya okunamadı: $e')),
          );
        }
      }
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testResultText = null;
      _testResultSuccess = null;
    });

    final port = int.tryParse(_portController.text.trim()) ?? 22;
    final result = await SshService.testConnection(
      host: _hostController.text.trim(),
      port: port,
      username: _usernameController.text.trim(),
      password: _authType == SshAuthType.password ? _passwordController.text : null,
      privateKeyContent: _authType != SshAuthType.password ? _keyContentController.text.trim() : null,
      passphrase: _passphraseController.text.trim().isNotEmpty ? _passphraseController.text.trim() : null,
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResultSuccess = result.success;
        _testResultText = result.success
            ? 'Bağlantı Başarılı! (Gecikme: ${result.pingMs} ms)'
            : 'Hata: ${result.errorMessage}';
      });
    }
  }

  void _saveServer() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 22;
    final username = _usernameController.text.trim();
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final notes = _notesController.text.trim();

    final serverProvider = context.read<ServerProvider>();

    if (widget.server == null) {
      // Add new
      await serverProvider.addServer(
        name: name,
        host: host,
        port: port,
        username: username,
        categoryId: _selectedCategoryId,
        authType: _authType,
        plainPassword: _authType == SshAuthType.password ? _passwordController.text : '',
        plainPrivateKey: _authType != SshAuthType.password ? _keyContentController.text.trim() : '',
        plainPassphrase: _passphraseController.text.trim(),
        tags: tags,
        notes: notes,
        colorHex: _selectedColorHex,
      );
    } else {
      // Update existing
      await serverProvider.updateServer(
        existingServer: widget.server!,
        name: name,
        host: host,
        port: port,
        username: username,
        categoryId: _selectedCategoryId,
        authType: _authType,
        plainPassword: _authType == SshAuthType.password ? _passwordController.text : '',
        plainPrivateKey: _authType != SshAuthType.password ? _keyContentController.text.trim() : '',
        plainPassphrase: _passphraseController.text.trim(),
        tags: tags,
        notes: notes,
        colorHex: _selectedColorHex,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dns_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.server == null ? 'Yeni SSH Sunucusu Ekle' : 'Sunucuyu Düzenle',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Form Body (Scrollable)
              Expanded(
                child: ListView(
                  children: [
                    // Row: Server Name & Category
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Sunucu Adı / Etiket *',
                              hintText: 'Örn: Prod Web 01, Hetzner DB',
                              prefixIcon: Icon(Icons.badge_outlined, size: 18, color: AppColors.textMuted),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Sunucu adı giriniz' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedCategoryId,
                            dropdownColor: AppColors.darkCard,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              prefixIcon: Icon(Icons.folder_outlined, size: 18, color: AppColors.textMuted),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Kategorisiz', style: TextStyle(color: AppColors.textMuted)),
                              ),
                              ...categoryProvider.categories.map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              ),
                            ],
                            onChanged: (val) => setState(() => _selectedCategoryId = val),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Row: Host, Port, Username
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: _hostController,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                            decoration: const InputDecoration(
                              labelText: 'Host / IP Adresi *',
                              hintText: '192.168.1.100 veya server.com',
                              prefixIcon: Icon(Icons.lan_outlined, size: 18, color: AppColors.textMuted),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'IP / Host giriniz' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _portController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Port *',
                              hintText: '22',
                              prefixIcon: Icon(Icons.numbers_rounded, size: 18, color: AppColors.textMuted),
                            ),
                            validator: (v) {
                              final p = int.tryParse(v ?? '');
                              if (p == null || p <= 0 || p > 65535) return 'Geçersiz port';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Kullanıcı Adı *',
                              hintText: 'root, ubuntu vb.',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textMuted),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Kullanıcı adı giriniz' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Auth Type Segment
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkInputBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _AuthTab(
                            title: 'Şifre İle',
                            icon: Icons.password_rounded,
                            isSelected: _authType == SshAuthType.password,
                            onTap: () => setState(() => _authType = SshAuthType.password),
                          ),
                          _AuthTab(
                            title: 'SSH Key Dosyası',
                            icon: Icons.file_present_rounded,
                            isSelected: _authType == SshAuthType.keyFile,
                            onTap: () => setState(() => _authType = SshAuthType.keyFile),
                          ),
                          _AuthTab(
                            title: 'SSH Key Metni',
                            icon: Icons.key_rounded,
                            isSelected: _authType == SshAuthType.keyText,
                            onTap: () => setState(() => _authType = SshAuthType.keyText),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Auth Fields
                    if (_authType == SshAuthType.password) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'SSH Şifresi',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Key Selection or Text Area
                      if (_authType == SshAuthType.keyFile) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.darkInputBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.darkBorder),
                                ),
                                child: Text(
                                  _pickedKeyFilePath ??
                                      (_keyContentController.text.isNotEmpty
                                          ? 'Yüklü SSH Private Key (Kayıtlı)'
                                          : 'Henüz dosya seçilmedi'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _keyContentController.text.isNotEmpty
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _pickKeyFile,
                              icon: const Icon(Icons.file_open_outlined, size: 16),
                              label: const Text('Dosya Seç...'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentIndigo,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _keyContentController,
                          maxLines: 4,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Private Key İçeriği (PEM/OpenSSH Formatında)',
                            hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _passphraseController,
                        obscureText: _obscurePassphrase,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Key Parolası (Passphrase - Varsa)',
                          hintText: 'Şifrelenmiş private key için opsiyonel parola',
                          prefixIcon: const Icon(Icons.key_rounded, size: 18, color: AppColors.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassphrase ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassphrase = !_obscurePassphrase),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Tags & Color
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _tagsController,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Etiketler (Virgülle Ayırın)',
                              hintText: 'web, prod, ubuntu, nginx',
                              prefixIcon: Icon(Icons.tag_rounded, size: 18, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Color Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Renk Rozeti', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 6),
                            Row(
                              children: AppColors.categoryColors.take(5).map((c) {
                                final hex = '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                                final isSelected = _selectedColorHex.toUpperCase() == hex.toUpperCase();
                                return InkWell(
                                  onTap: () => setState(() => _selectedColorHex = hex),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Sunucu Notları (Opsiyonel)',
                        hintText: 'Sunucu ile ilgili özel açıklamalar veya portlar...',
                        prefixIcon: Icon(Icons.notes_rounded, size: 18, color: AppColors.textMuted),
                      ),
                    ),

                    // Test Connection Result Message
                    if (_testResultText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _testResultSuccess == true
                              ? AppColors.statusOnline.withValues(alpha: 0.15)
                              : AppColors.statusError.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _testResultSuccess == true ? AppColors.statusOnline : AppColors.statusError,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _testResultSuccess == true ? Icons.check_circle_outline : Icons.error_outline,
                              size: 16,
                              color: _testResultSuccess == true ? AppColors.statusOnline : AppColors.statusError,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _testResultText!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _testResultSuccess == true ? AppColors.statusOnline : AppColors.statusError,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 14),

              // Bottom Actions
              Row(
                children: [
                  // Test Connection Button
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.network_check_rounded, size: 16),
                    label: Text(_isTesting ? 'Test Ediliyor...' : 'Bağlantıyı Test Et'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saveServer,
                    child: Text(widget.server == null ? 'Sunucuyu Kaydet' : 'Değişiklikleri Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthTab({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
