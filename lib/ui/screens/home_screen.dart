import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/server_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/terminal_provider.dart';
import '../widgets/custom_window_title_bar.dart';
import '../widgets/quick_connect_dialog.dart';
import '../widgets/server_card.dart';
import '../widgets/server_form_dialog.dart';
import '../widgets/sidebar.dart';
import 'settings_screen.dart';
import 'terminal_tab_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isGridView = true;
  double _terminalHeight = 320;

  @override
  Widget build(BuildContext context) {
    final serverProvider = context.watch<ServerProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final terminalProvider = context.watch<TerminalProvider>();
    final authProvider = context.watch<AuthProvider>();

    final selectedCat = categoryProvider.selectedCategory;
    final filteredServers = serverProvider.getFilteredServers(
      categoryId: categoryProvider.selectedCategoryId,
    );

    final showTerminal = terminalProvider.sessions.isNotEmpty && terminalProvider.isTerminalVisible;

    return Listener(
      onPointerDown: (_) => authProvider.reportUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Column(
          children: [
            // Custom Desktop Title Bar
            CustomWindowTitleBar(
              onOpenSettings: () => _openSettings(context),
              onQuickConnect: () => _openQuickConnect(context),
            ),

            // Main Workspace Layout
            Expanded(
              child: Row(
                children: [
                  // Sidebar
                  Sidebar(
                    onAddServer: () => _openServerForm(context),
                  ),

                  // Main Content & Terminal Split
                  Expanded(
                    child: Column(
                      children: [
                        // Server Management Area
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Sub-header (Category title, View Mode, Quick Stats)
                              _buildTopBar(
                                selectedCatTitle: selectedCat != null
                                    ? selectedCat.name
                                    : serverProvider.favoritesOnly
                                        ? 'Favori Sunucular'
                                        : 'Tüm Sunucular',
                                serverCount: filteredServers.length,
                                totalCount: serverProvider.servers.length,
                                onAddServer: () => _openServerForm(context),
                                onQuickConnect: () => _openQuickConnect(context),
                              ),

                              const Divider(),

                              // Server Grid / List
                              Expanded(
                                child: filteredServers.isEmpty
                                    ? _buildEmptyState(context)
                                    : _isGridView
                                        ? _buildGridView(filteredServers)
                                        : _buildTableView(filteredServers, context, serverProvider, terminalProvider),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Embedded SSH Terminal (Resizable)
                        if (showTerminal) ...[
                          // Resize Handle Bar
                          GestureDetector(
                            onVerticalDragUpdate: (details) {
                              setState(() {
                                _terminalHeight = (_terminalHeight - details.delta.dy).clamp(180.0, 650.0);
                              });
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeUpDown,
                              child: Container(
                                height: 6,
                                color: AppColors.darkSidebar,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 36,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkBorder,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Terminal View Widget
                          SizedBox(
                            height: _terminalHeight,
                            child: TerminalTabView(
                              onMinimizeOrClose: () => terminalProvider.toggleTerminal(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar({
    required String selectedCatTitle,
    required int serverCount,
    required int totalCount,
    required VoidCallback onAddServer,
    required VoidCallback onQuickConnect,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    selectedCatTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$serverCount Sunucu',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),

          // Grid / List View Toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkInputBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: _isGridView ? AppColors.primary : AppColors.textMuted,
                  ),
                  tooltip: 'Kart Görünümü',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _isGridView = true),
                ),
                IconButton(
                  icon: Icon(
                    Icons.view_list_rounded,
                    size: 18,
                    color: !_isGridView ? AppColors.primary : AppColors.textMuted,
                  ),
                  tooltip: 'Liste Görünümü',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _isGridView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<ServerModel> servers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 700) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1050) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth > 1450) {
          crossAxisCount = 4;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 215,
          ),
          itemCount: servers.length,
          itemBuilder: (ctx, index) {
            final server = servers[index];
            return ServerCard(
              server: server,
              onEdit: () => _openServerForm(context, server: server),
              onDuplicate: () => _duplicateServer(context, server),
            );
          },
        );
      },
    );
  }

  Widget _buildTableView(
    List<ServerModel> servers,
    BuildContext context,
    ServerProvider serverProvider,
    TerminalProvider terminalProvider,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: servers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) {
        final server = servers[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dns_rounded, color: AppColors.primary, size: 18),
            ),
            title: Row(
              children: [
                Text(server.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 10),
                Text(
                  '${server.username}@${server.host}:${server.port}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.accentCyan),
                ),
              ],
            ),
            subtitle: Text(
              server.tags.isNotEmpty ? server.tags.map((t) => '#$t').join(' ') : 'Kategorisiz',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    server.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: server.isFavorite ? AppColors.accentAmber : AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => serverProvider.toggleFavorite(server),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    serverProvider.markConnected(server.id);
                    final creds = serverProvider.decryptCredentials(server);
                    terminalProvider.openServerSession(
                      server: server,
                      decryptedPassword: creds.password,
                      decryptedPrivateKey: creds.privateKey,
                      decryptedPassphrase: creds.passphrase,
                    );
                  },
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Bağlan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Icon(Icons.dns_rounded, size: 48, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sunucu Bulunamadı',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bu kategoride kayıtlı sunucu yok veya arama kriterine uyan sunucu bulunamadı.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openServerForm(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Yeni Sunucu Ekle'),
          ),
        ],
      ),
    );
  }

  void _openServerForm(BuildContext context, {ServerModel? server}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ServerFormDialog(server: server),
    );
  }

  void _duplicateServer(BuildContext context, ServerModel server) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ServerFormDialog(
        server: server.copyWith(name: '${server.name} (Kopya)'),
      ),
    );
  }

  void _openQuickConnect(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const QuickConnectDialog(),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
    );
  }
}
