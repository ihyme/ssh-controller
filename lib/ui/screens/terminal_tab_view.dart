import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/server_provider.dart';
import '../../providers/terminal_provider.dart';
import '../../services/terminal_manager.dart';
import '../widgets/snippet_bar.dart';

class TerminalTabView extends StatelessWidget {
  final VoidCallback? onMinimizeOrClose;

  const TerminalTabView({
    super.key,
    this.onMinimizeOrClose,
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
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sessions.length,
                    itemBuilder: (ctx, idx) {
                      final s = sessions[idx];
                      final isSelected = idx == activeIndex;
                      return _TerminalTabItem(
                        session: s,
                        isSelected: isSelected,
                        onTap: () => terminalProvider.setActiveTab(idx),
                        onClose: () => terminalProvider.closeTab(idx),
                      );
                    },
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

                    // Reconnect Button
                    if (activeSession != null && activeSession.status != TerminalSessionStatus.connected)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primaryLight),
                        tooltip: 'Yeniden Bağlan',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          final creds = serverProvider.decryptCredentials(activeSession.server);
                          terminalProvider.closeTab(activeIndex);
                          terminalProvider.openServerSession(
                            server: activeSession.server,
                            decryptedPassword: creds.password,
                            decryptedPrivateKey: creds.privateKey,
                            decryptedPassphrase: creds.passphrase,
                          );
                        },
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

          // Active Terminal Widget Area
          Expanded(
            child: activeSession != null
                ? Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    color: AppColors.terminalBg,
                    child: TerminalView(
                      activeSession.terminal,
                      textStyle: TerminalStyle(
                        fontSize: terminalProvider.fontSize,
                        fontFamily: GoogleFonts.jetBrainsMono().fontFamily ?? 'monospace',
                      ),
                      theme: _getTerminalTheme(terminalProvider.themeName),
                      autofocus: true,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  TerminalTheme _getTerminalTheme(String name) {
    // Custom Cyber Terminal theme
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

  const _TerminalTabItem({
    required this.session,
    required this.isSelected,
    required this.onTap,
    required this.onClose,
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.terminalBg
                : _isHovered
                    ? AppColors.darkCardHover
                    : Colors.transparent,
            border: Border(
              right: const BorderSide(color: AppColors.terminalBorder, width: 1),
              top: widget.isSelected
                  ? const BorderSide(color: AppColors.primary, width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
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
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Close Tab
              InkWell(
                onTap: widget.onClose,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: widget.isSelected ? AppColors.textSecondary : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
