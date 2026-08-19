import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../providers/category_provider.dart';

class CategoryDialog extends StatefulWidget {
  final CategoryModel? category;

  const CategoryDialog({
    super.key,
    this.category,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColorHex;

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'folder', 'icon': Icons.folder_rounded, 'label': 'Klasör'},
    {'name': 'globe', 'icon': Icons.language_rounded, 'label': 'Web'},
    {'name': 'database', 'icon': Icons.storage_rounded, 'label': 'Veritabanı'},
    {'name': 'server', 'icon': Icons.dns_rounded, 'label': 'Sunucu'},
    {'name': 'code', 'icon': Icons.code_rounded, 'label': 'Kod / Dev'},
    {'name': 'shield', 'icon': Icons.security_rounded, 'label': 'Güvenlik'},
    {'name': 'cloud', 'icon': Icons.cloud_outlined, 'label': 'Bulut'},
    {'name': 'terminal', 'icon': Icons.terminal_rounded, 'label': 'Terminal'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? 'folder';
    _selectedColorHex = widget.category?.colorHex ?? '#10B981';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final categoryProvider = context.read<CategoryProvider>();

    if (widget.category == null) {
      await categoryProvider.addCategory(
        name: name,
        icon: _selectedIcon,
        colorHex: _selectedColorHex,
      );
    } else {
      await categoryProvider.updateCategory(
        widget.category!.copyWith(
          name: name,
          icon: _selectedIcon,
          colorHex: _selectedColorHex,
        ),
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
        width: 440,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_special_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.category == null ? 'Yeni Kategori Oluştur' : 'Kategoriyi Düzenle',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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

              // Category Name
              TextFormField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı *',
                  hintText: 'Örn: Web Sunucuları, Production, Test',
                  prefixIcon: Icon(Icons.label_outline, size: 18, color: AppColors.textMuted),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Kategori adı giriniz' : null,
              ),

              const SizedBox(height: 14),

              // Icon Picker
              const Text('Simge Seçin', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableIcons.map((item) {
                  final isSelected = _selectedIcon == item['name'];
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = item['name'] as String),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.darkInputBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.darkBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 16,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Color Picker
              const Text('Renk Seçin', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: AppColors.categoryColors.map((c) {
                  final hex = '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                  final isSelected = _selectedColorHex.toUpperCase() == hex.toUpperCase();
                  return InkWell(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 14),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveCategory,
                    child: Text(widget.category == null ? 'Kategori Ekle' : 'Güncelle'),
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
