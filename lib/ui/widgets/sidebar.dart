import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/server_provider.dart';
import 'category_dialog.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onAddServer;

  const Sidebar({
    super.key,
    required this.onAddServer,
  });

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final serverProvider = context.watch<ServerProvider>();

    final totalServersCount = serverProvider.servers.length;
    final favoriteServersCount = serverProvider.servers.where((s) => s.isFavorite).length;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.darkSidebar,
        border: Border(
          right: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add Server Main Button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: ElevatedButton.icon(
              onPressed: onAddServer,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Yeni Sunucu Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              onChanged: (val) => serverProvider.setSearchQuery(val),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Sunucu, IP veya etiket ara...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                suffixIcon: serverProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                        onPressed: () => serverProvider.setSearchQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Nav Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                // All Servers Item
                _SidebarItem(
                  icon: Icons.dns_rounded,
                  title: 'Tüm Sunucular',
                  count: totalServersCount,
                  isSelected: categoryProvider.selectedCategoryId == null && !serverProvider.favoritesOnly,
                  color: AppColors.primary,
                  onTap: () {
                    if (serverProvider.favoritesOnly) serverProvider.toggleFavoritesOnly();
                    categoryProvider.selectCategory(null);
                  },
                ),

                // Favorites Item
                _SidebarItem(
                  icon: Icons.star_rounded,
                  title: 'Favori Sunucular',
                  count: favoriteServersCount,
                  isSelected: serverProvider.favoritesOnly,
                  color: AppColors.accentAmber,
                  onTap: () {
                    serverProvider.toggleFavoritesOnly();
                  },
                ),

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),

                // Categories Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Text(
                        'KATEGORİLER',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Kategori Ekle',
                        icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.textSecondary),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showAddCategoryDialog(context),
                      ),
                    ],
                  ),
                ),

                // Category List
                ...categoryProvider.categories.map((category) {
                  final count = serverProvider.servers.where((s) => s.categoryId == category.id).length;
                  final isSelected = categoryProvider.selectedCategoryId == category.id && !serverProvider.favoritesOnly;
                  final catColor = _hexToColor(category.colorHex);

                  return _SidebarItem(
                    icon: _getCategoryIcon(category.icon),
                    title: category.name,
                    count: count,
                    isSelected: isSelected,
                    color: catColor,
                    onTap: () {
                      if (serverProvider.favoritesOnly) serverProvider.toggleFavoritesOnly();
                      categoryProvider.selectCategory(category.id);
                    },
                    onEdit: () => _showEditCategoryDialog(context, category),
                    onDelete: () => _showDeleteCategoryDialog(context, category),
                  );
                }),

                const SizedBox(height: 14),

                // Tags Section
                if (serverProvider.allTags.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'ETİKETLER',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: serverProvider.allTags.map((tag) {
                      final isSelected = serverProvider.selectedTag == tag;
                      return FilterChip(
                        label: Text('#$tag'),
                        selected: isSelected,
                        onSelected: (selected) {
                          serverProvider.setSelectedTag(selected ? tag : null);
                        },
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        backgroundColor: AppColors.darkCard,
                        selectedColor: AppColors.accentCyan.withValues(alpha: 0.3),
                        side: BorderSide(
                          color: isSelected ? AppColors.accentCyan : AppColors.darkBorder,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CategoryDialog(),
    );
  }

  void _showEditCategoryDialog(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => CategoryDialog(category: category),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text('"${category.name}" kategorisini silmek istediğinizden emin misiniz? Sunucular silinmeyecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusError),
            onPressed: () {
              context.read<CategoryProvider>().deleteCategory(category.id);
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

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'globe': return Icons.language_rounded;
      case 'database': return Icons.storage_rounded;
      case 'server': return Icons.dns_rounded;
      case 'code': return Icons.code_rounded;
      case 'shield': return Icons.security_rounded;
      case 'cloud': return Icons.cloud_outlined;
      case 'terminal': return Icons.terminal_rounded;
      default: return Icons.folder_rounded;
    }
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? widget.color.withValues(alpha: 0.15)
              : _isHovered
                  ? AppColors.darkCardHover
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSelected ? widget.color.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          leading: Icon(
            widget.icon,
            size: 18,
            color: widget.isSelected ? widget.color : AppColors.textSecondary,
          ),
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
              color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isHovered && (widget.onEdit != null || widget.onDelete != null)) ...[
                if (widget.onEdit != null)
                  InkWell(
                    onTap: widget.onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(Icons.edit_outlined, size: 14, color: AppColors.textMuted),
                    ),
                  ),
                const SizedBox(width: 4),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.color.withValues(alpha: 0.25)
                      : AppColors.darkCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.isSelected ? widget.color : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
