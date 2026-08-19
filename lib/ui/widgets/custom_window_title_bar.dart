import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/terminal_provider.dart';

class CustomWindowTitleBar extends StatefulWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onQuickConnect;

  const CustomWindowTitleBar({
    super.key,
    required this.onOpenSettings,
    required this.onQuickConnect,
  });

  @override
  State<CustomWindowTitleBar> createState() => _CustomWindowTitleBarState();
}

class _CustomWindowTitleBarState extends State<CustomWindowTitleBar> with WindowListener {
  bool _isMaximized = false;
  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    if (_isDesktop) {
      final max = await windowManager.isMaximized();
      if (mounted) {
        setState(() => _isMaximized = max);
      }
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    final terminalProvider = context.watch<TerminalProvider>();
    final authProvider = context.watch<AuthProvider>();
    final activeSessionsCount = terminalProvider.sessions.length;

    Widget titleRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accentCyan],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.terminal_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'RoPi SSH',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (activeSessionsCount > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.statusOnline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$activeSessionsCount Aktif Oturum',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.darkSidebar,
        border: Border(
          bottom: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // App Icon & Title
          Expanded(
            child: _isDesktop ? DragToMoveArea(child: titleRow) : titleRow,
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick Connect Button
              TextButton.icon(
                onPressed: widget.onQuickConnect,
                icon: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.accentAmber),
                label: const Text(
                  'Hızlı Bağlan',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
              const SizedBox(width: 4),

              // Lock Button (if master pass enabled)
              if (authProvider.hasMasterPassword)
                IconButton(
                  tooltip: 'Uygulamayı Kilitle',
                  icon: const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textSecondary),
                  onPressed: () => authProvider.lock(),
                  visualDensity: VisualDensity.compact,
                ),

              // Settings Button
              IconButton(
                tooltip: 'Ayarlar',
                icon: const Icon(Icons.settings_outlined, size: 16, color: AppColors.textSecondary),
                onPressed: widget.onOpenSettings,
                visualDensity: VisualDensity.compact,
              ),

              const SizedBox(width: 8),

              // Windows / Linux Window Control Buttons
              if (Platform.isWindows || Platform.isLinux) ...[
                _WindowButton(
                  icon: Icons.minimize_rounded,
                  onPressed: () => windowManager.minimize(),
                ),
                _WindowButton(
                  icon: _isMaximized ? Icons.crop_square_rounded : Icons.crop_din_rounded,
                  onPressed: () async {
                    if (_isMaximized) {
                      await windowManager.unmaximize();
                    } else {
                      await windowManager.maximize();
                    }
                  },
                ),
                _WindowButton(
                  icon: Icons.close_rounded,
                  isClose: true,
                  onPressed: () => windowManager.close(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color hoverColor = widget.isClose ? Colors.red.shade600 : AppColors.darkBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 44,
          height: 42,
          color: _isHovered ? hoverColor : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: 15,
            color: _isHovered && widget.isClose ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
