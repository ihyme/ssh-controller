import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/server_provider.dart';
import '../../providers/terminal_provider.dart';
import '../../services/terminal_manager.dart';
import '../widgets/quick_connect_dialog.dart';
import '../widgets/snippet_bar.dart';

class TerminalTabView extends StatelessWidget {
  final VoidCallback? onMinimizeOrClose;
  final VoidCallback? onToggleFullscreen;
  final bool isFullscreen;

  const TerminalTabView({
    super.key,
    this.onMinimizeOrClose,
    this.onToggleFullscreen,
    this.isFullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final terminalProvider = context.watch<TerminalProvider>();
    final serverProvider = context.read<ServerProvider>();
    final sessions = terminalProvider.sessions;
    final activeIndex = terminalProvider.activeIndex;

    if (sessions.isEmpty) {
      return Container(
        color: AppColors.terminalBg,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.terminal_rounded, size: 48, color: AppColors.darkBorder),
            const SizedBox(height: 12),
            const Text(
              'Açık bir SSH oturumu bulunmuyor',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sol veya üst paneldeki sunuculardan birine tıklayarak doğrudan SSH açabilirsiniz.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final activeSession = terminalProvider.activeSession;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.terminalBg,
        border: Border(
          top: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Tab Header Bar
          Container(
            height: 38,
            color: AppColors.terminalHeader,
            child: Row(
              children: [
                // Tabs List
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: sessions.length,
                          itemBuilder: (ctx, idx) {
                            final s = sessions[idx];
                            final isSelected = idx == activeIndex;
                            return _TerminalTabItem(
                              session: s,
                              isSelected: isSelected,
                              onTap: () => terminalProvider.setActiveTab(idx),
                              onClose: () => terminalProvider.closeTab(idx),
                              onDuplicate: () {
                                final creds = serverProvider.decryptCredentials(s.server);
                                terminalProvider.openServerSession(
                                  server: s.server,
                                  decryptedPassword: creds.password,
                                  decryptedPrivateKey: creds.privateKey,
                                  decryptedPassphrase: creds.passphrase,
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // "+" New Tab Quick Button
                      PopupMenuButton<String>(
                        tooltip: 'Yeni Sekme Aç',
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.terminalBorder),
                          ),
                          child: const Icon(Icons.add_rounded, size: 14, color: AppColors.primaryLight),
                        ),
                        color: AppColors.darkCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.darkBorder),
                        ),
                        onSelected: (val) {
                          if (val == '__quick_connect__') {
                            showDialog(context: context, builder: (ctx) => const QuickConnectDialog());
                          } else {
                            final server = serverProvider.servers.firstWhere((s) => s.id == val);
                            final creds = serverProvider.decryptCredentials(server);
                            terminalProvider.openServerSession(
                              server: server,
                              decryptedPassword: creds.password,
                              decryptedPrivateKey: creds.privateKey,
                              decryptedPassphrase: creds.passphrase,
                            );
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: '__quick_connect__',
                            child: Row(
                              children: [
                                Icon(Icons.flash_on_rounded, size: 16, color: AppColors.accentAmber),
                                SizedBox(width: 8),
                                Text('Hızlı Bağlan (Manuel IP)', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          if (serverProvider.servers.isNotEmpty) ...[
                            const PopupMenuDivider(),
                            ...serverProvider.servers.map(
                              (s) => PopupMenuItem(
                                value: s.id,
                                child: Row(
                                  children: [
                                    const Icon(Icons.dns_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text('${s.name} (${s.username}@${s.host})', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab Actions: Zoom - / +, Clear, Reconnect, Close All, Minimize
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom Out
                    IconButton(
                      icon: const Icon(Icons.zoom_out_rounded, size: 16, color: AppColors.textSecondary),
                      tooltip: 'Yazı Tipini Küçült',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => terminalProvider.zoomOut(),
                    ),
                    // Font size indicator
                    Text(
                      '${terminalProvider.fontSize.toInt()}pt',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    // Zoom In
                    IconButton(
                      icon: const Icon(Icons.zoom_in_rounded, size: 16, color: AppColors.textSecondary),
                      tooltip: 'Yazı Tipini Büyüt',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => terminalProvider.zoomIn(),
                    ),

                    const VerticalDivider(indent: 8, endIndent: 8),

                    // Clear Terminal
                    if (activeSession != null)
                      IconButton(
                        icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: AppColors.textSecondary),
                        tooltip: 'Terminali Temizle',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          activeSession.terminal.eraseDisplay();
                        },
                      ),

                    // Reconnect / Connect Button
                    if (activeSession != null && activeSession.status != TerminalSessionStatus.connected)
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 18, color: AppColors.primaryLight),
                        tooltip: 'Bağlantıyı Başlat / Yeniden Bağlan',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          final creds = serverProvider.decryptCredentials(activeSession.server);
                          terminalProvider.reconnectTab(
                            index: activeIndex,
                            decryptedPassword: creds.password,
                            decryptedPrivateKey: creds.privateKey,
                            decryptedPassphrase: creds.passphrase,
                          );
                        },
                      ),

                    // Close All Tabs Button
                    IconButton(
                      icon: const Icon(Icons.close_fullscreen_rounded, size: 15, color: AppColors.textMuted),
                      tooltip: 'Tüm Sekmeleri Kapat',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => terminalProvider.closeAllTabs(),
                    ),

                    // Maximize / Restore Terminal Button
                    if (onToggleFullscreen != null)
                      IconButton(
                        icon: Icon(
                          isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: isFullscreen ? 'Bölünmüş Görünüme Dön' : 'Terminali Büyüt (Tam Ekran)',
                        visualDensity: VisualDensity.compact,
                        onPressed: onToggleFullscreen,
                      ),

                    // Minimize / Toggle Terminal
                    if (onMinimizeOrClose != null)
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                        tooltip: 'Terminali Gizle',
                        visualDensity: VisualDensity.compact,
                        onPressed: onMinimizeOrClose,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Snippet Bar for Quick Commands
          const SnippetBar(),

          // Multi-tab Terminal Widget Stack (IndexedStack for persistent terminal state across tabs)
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              color: AppColors.terminalBg,
              child: IndexedStack(
                index: activeIndex.clamp(0, sessions.isEmpty ? 0 : sessions.length - 1),
                children: sessions.map((session) {
                  return TerminalView(
                    session.terminal,
                    textStyle: TerminalStyle(
                      fontSize: terminalProvider.fontSize,
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily ?? 'monospace',
                    ),
                    theme: _getTerminalTheme(terminalProvider.themeName),
                    autofocus: true,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TerminalTheme _getTerminalTheme(String name) {
    return const TerminalTheme(
      cursor: Color(0xFF10B981),
      selection: Color(0x5510B981),
      foreground: Color(0xFFE2E8F0),
      background: Color(0xFF0D1117),
      black: Color(0xFF484F58),
      red: Color(0xFFFF7B72),
      green: Color(0xFF3FB950),
      yellow: Color(0xFFD29922),
      blue: Color(0xFF58A6FF),
      magenta: Color(0xFFBC8CFF),
      cyan: Color(0xFF39C5CF),
      white: Color(0xFFB1BAC4),
      brightBlack: Color(0xFF6E7681),
      brightRed: Color(0xFFFFA198),
      brightGreen: Color(0xFF56D364),
      brightYellow: Color(0xFFE3B341),
      brightBlue: Color(0xFF79C0FF),
      brightMagenta: Color(0xFFD2A8FF),
      brightCyan: Color(0xFF56D4DD),
      brightWhite: Color(0xFFF0F6FC),
      searchHitBackground: Color(0xFF58A6FF),
      searchHitBackgroundCurrent: Color(0xFFF0883E),
      searchHitForeground: Color(0xFF0D1117),
    );
  }
}

class _TerminalTabItem extends StatefulWidget {
  final TerminalSession session;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onDuplicate;

  const _TerminalTabItem({
    required this.session,
    required this.isSelected,
    required this.onTap,
    required this.onClose,
    required this.onDuplicate,
  });

  @override
  State<_TerminalTabItem> createState() => _TerminalTabItemState();
}

class _TerminalTabItemState extends State<_TerminalTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (widget.session.status) {
      case TerminalSessionStatus.connected:
        statusColor = AppColors.statusOnline;
        break;
      case TerminalSessionStatus.connecting:
        statusColor = AppColors.statusConnecting;
        break;
      case TerminalSessionStatus.error:
        statusColor = AppColors.statusError;
        break;
      case TerminalSessionStatus.disconnected:
        statusColor = AppColors.statusOffline;
        break;
    }

    final serverColor = _hexToColor(widget.session.server.colorHex);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? serverColor.withValues(alpha: 0.14)
                : _isHovered
                    ? serverColor.withValues(alpha: 0.08)
                    : Colors.transparent,
            border: Border(
              right: const BorderSide(color: AppColors.terminalBorder, width: 1),
              top: widget.isSelected
                  ? BorderSide(color: serverColor, width: 2.5)
                  : const BorderSide(color: Colors.transparent, width: 2.5),
              bottom: widget.isSelected
                  ? BorderSide.none
                  : BorderSide(color: serverColor.withValues(alpha: 0.3), width: 1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Server Color Dot / Tag
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: serverColor,
                  shape: BoxShape.circle,
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: serverColor.withValues(alpha: 0.8),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),

              // Title
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  widget.session.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.normal,
                    color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),

              // Status dot (online/offline)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),

              // Close Tab Button
              InkWell(
                onTap: widget.onClose,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: widget.isSelected ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xFF10B981);
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      color: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      items: [
        PopupMenuItem(
          onTap: widget.onDuplicate,
          child: const Row(
            children: [
              Icon(Icons.copy_rounded, size: 14, color: AppColors.accentCyan),
              SizedBox(width: 8),
              Text('Aynı Sunucuya Yeni Sekme Aç', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: widget.onClose,
          child: const Row(
            children: [
              Icon(Icons.close_rounded, size: 14, color: AppColors.statusError),
              SizedBox(width: 8),
              Text('Bu Sekmeyi Kapat', style: TextStyle(fontSize: 12, color: AppColors.statusError)),
            ],
          ),
        ),
      ],
    );
  }
}
