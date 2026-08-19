import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/server_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/terminal_provider.dart';
import '../../services/external_terminal_service.dart';

class ServerCard extends StatefulWidget {
  final ServerModel server;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;

  const ServerCard({
    super.key,
    required this.server,
    required this.onEdit,
    required this.onDuplicate,
  });

  @override
  State<ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<ServerCard> {
  bool _isHovered = false;
  bool _isTestingPing = false;

  @override
  Widget build(BuildContext context) {
    final serverProvider = context.watch<ServerProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final terminalProvider = context.watch<TerminalProvider>();

    final category = widget.server.categoryId != null
        ? categoryProvider.categories.where((c) => c.id == widget.server.categoryId).firstOrNull
        : null;

    final badgeColor = _hexToColor(widget.server.colorHex);
    final latency = serverProvider.serverLatencies[widget.server.id];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.darkCardHover : AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.darkBorder,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header: Color bar / Icon + Title + Fav + Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Icon(
                      Icons.dns_rounded,
                      color: badgeColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.server.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (category != null)
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: _hexToColor(category.colorHex),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      widget.server.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: widget.server.isFavorite ? AppColors.accentAmber : AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => serverProvider.toggleFavorite(widget.server),
                    visualDensity: VisualDensity.compact,
                    tooltip: widget.server.isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                  ),

                  // Context Popup Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                    color: AppColors.darkCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.darkBorder),
                    ),
                    onSelected: (val) => _handleMenuAction(val, context, serverProvider, terminalProvider),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'connect_tab',
                        child: Row(
                          children: [
                            Icon(Icons.terminal_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Dahili Terminalde Aç', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'connect_external',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.accentCyan),
                            SizedBox(width: 8),
                            Text('Harici Terminalde Aç', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'ping',
                        child: Row(
                          children: [
                            Icon(Icons.network_check_rounded, size: 16, color: AppColors.accentAmber),
                            SizedBox(width: 8),
                            Text('Bağlantıyı Test Et (Ping)', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Text('Düzenle', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Text('Çoğalt', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.statusError),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(fontSize: 13, color: AppColors.statusError)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Server Details: IP, Port, Username & Auth Type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkInputBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lan_outlined, size: 14, color: AppColors.accentCyan),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${widget.server.username}@${widget.server.host}:${widget.server.port}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          widget.server.authType == SshAuthType.password
                              ? Icons.password_rounded
                              : Icons.key_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.server.authType == SshAuthType.password ? 'Şifre' : 'SSH Private Key',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        // Latency / Status indicator
                        if (_isTestingPing)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        else if (latency != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: latency > 0 ? AppColors.statusOnline : AppColors.statusError,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                latency > 0 ? '$latency ms' : 'Hata',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: latency > 0 ? AppColors.statusOnline : AppColors.statusError,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tags
              if (widget.server.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.server.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.darkBorder.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Action Footer: Last Connected + Direct Connect Button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.server.lastConnectedAt != null
                          ? 'Son: ${DateFormat('dd.MM HH:mm').format(widget.server.lastConnectedAt!)}'
                          : 'Henüz bağlanılmadı',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ONE-CLICK CONNECT BUTTON
                  ElevatedButton.icon(
                    onPressed: () => _connectDirectly(context, serverProvider, terminalProvider),
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text('Bağlan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _connectDirectly(BuildContext context, ServerProvider serverProvider, TerminalProvider terminalProvider) {
    serverProvider.markConnected(widget.server.id);
    final creds = serverProvider.decryptCredentials(widget.server);

    terminalProvider.openServerSession(
      server: widget.server,
      decryptedPassword: creds.password,
      decryptedPrivateKey: creds.privateKey,
      decryptedPassphrase: creds.passphrase,
    );
  }

  void _handleMenuAction(
    String action,
    BuildContext context,
    ServerProvider serverProvider,
    TerminalProvider terminalProvider,
  ) async {
    switch (action) {
      case 'connect_tab':
        _connectDirectly(context, serverProvider, terminalProvider);
        break;
      case 'connect_external':
        ExternalTerminalService.launch(
          host: widget.server.host,
          port: widget.server.port,
          username: widget.server.username,
        );
        break;
      case 'ping':
        setState(() => _isTestingPing = true);
        await serverProvider.pingServer(widget.server);
        if (mounted) setState(() => _isTestingPing = false);
        break;
      case 'edit':
        widget.onEdit();
        break;
      case 'duplicate':
        widget.onDuplicate();
        break;
      case 'delete':
        _confirmDelete(context, serverProvider);
        break;
    }
  }

  void _confirmDelete(BuildContext context, ServerProvider serverProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sunucuyu Sil'),
        content: Text('"${widget.server.name}" sunucusunu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusError),
            onPressed: () {
              serverProvider.deleteServer(widget.server.id);
              Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xFF10B981);
  }
}
