import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/server_model.dart';
import '../../providers/server_provider.dart';
import '../../providers/terminal_provider.dart';

class QuickConnectDialog extends StatefulWidget {
  const QuickConnectDialog({super.key});

  @override
  State<QuickConnectDialog> createState() => _QuickConnectDialogState();
}

class _QuickConnectDialogState extends State<QuickConnectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController(text: 'root');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _saveToDatabase = false;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _connect() async {
    if (!_formKey.currentState!.validate()) return;

    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 22;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : '$username@$host';

    final terminalProvider = context.read<TerminalProvider>();
    final serverProvider = context.read<ServerProvider>();

    if (_saveToDatabase) {
      final savedServer = await serverProvider.addServer(
        name: name,
        host: host,
        port: port,
        username: username,
        plainPassword: password,
      );
      terminalProvider.openServerSession(
        server: savedServer,
        decryptedPassword: password,
        decryptedPrivateKey: '',
        decryptedPassphrase: '',
      );
    } else {
      final tempServer = ServerModel(
        id: const Uuid().v4(),
        name: name,
        host: host,
        port: port,
        username: username,
      );
      terminalProvider.openServerSession(
        server: tempServer,
        decryptedPassword: password,
        decryptedPrivateKey: '',
        decryptedPassphrase: '',
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppColors.accentAmber, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Hızlı SSH Bağlantısı',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 14),

              // Host & Port
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _hostController,
                      autofocus: true,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        labelText: 'Host / IP *',
                        hintText: '192.168.1.1 veya server.com',
                        prefixIcon: Icon(Icons.lan_outlined, size: 18, color: AppColors.textMuted),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Host giriniz' : null,
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
                        labelText: 'Port',
                        hintText: '22',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Username
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı *',
                  hintText: 'root, ubuntu, debian',
                  prefixIcon: Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Kullanıcı adı giriniz' : null,
              ),

              const SizedBox(height: 12),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
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

              const SizedBox(height: 10),

              // Checkbox: Save to database
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _saveToDatabase,
                onChanged: (val) => setState(() => _saveToDatabase = val ?? false),
                title: const Text('Bu sunucuyu listeme de kaydet', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              if (_saveToDatabase) ...[
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Sunucu İçin Bir İsim Belirleyin',
                    hintText: 'Örn: Test Sunucum',
                    prefixIcon: Icon(Icons.badge_outlined, size: 18, color: AppColors.textMuted),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _connect,
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text('Bağlan'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber),
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
