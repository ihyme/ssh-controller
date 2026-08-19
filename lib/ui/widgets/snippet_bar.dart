import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/snippet_model.dart';
import '../../providers/snippet_provider.dart';
import '../../providers/terminal_provider.dart';

class SnippetBar extends StatelessWidget {
  const SnippetBar({super.key});

  @override
  Widget build(BuildContext context) {
    final snippetProvider = context.watch<SnippetProvider>();
    final terminalProvider = context.watch<TerminalProvider>();

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.terminalHeader,
        border: Border(
          top: BorderSide(color: AppColors.terminalBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.accentAmber),
          const SizedBox(width: 6),
          const Text(
            'Hızlı Komutlar:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),

          // Snippet Chips
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: snippetProvider.snippets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (ctx, index) {
                final snippet = snippetProvider.snippets[index];
                return _SnippetChip(
                  snippet: snippet,
                  onTap: () {
                    terminalProvider.sendCommand(snippet.command);
                  },
                  onDelete: () {
                    snippetProvider.deleteSnippet(snippet.id);
                  },
                );
              },
            ),
          ),

          const SizedBox(width: 6),

          // Add Snippet Button
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryLight),
            tooltip: 'Yeni Hızlı Komut Ekle',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showAddSnippetDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAddSnippetDialog(BuildContext context) {
    final titleController = TextEditingController();
    final cmdController = TextEditingController();
    final catController = TextEditingController(text: 'Genel');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Hızlı Komut Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Komut Başlığı', hintText: 'Örn: Docker Durumu'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cmdController,
              decoration: const InputDecoration(labelText: 'Çalıştırılacak Komut', hintText: 'Örn: docker ps -a'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: catController,
              decoration: const InputDecoration(labelText: 'Kategori', hintText: 'Genel, Docker, Sistem'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty && cmdController.text.trim().isNotEmpty) {
                context.read<SnippetProvider>().addSnippet(
                  title: titleController.text.trim(),
                  command: cmdController.text.trim(),
                  category: catController.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}

class _SnippetChip extends StatefulWidget {
  final SnippetModel snippet;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SnippetChip({
    required this.snippet,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_SnippetChip> createState() => _SnippetChipState();
}

class _SnippetChipState extends State<_SnippetChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.darkCardHover : AppColors.darkInputBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.terminalBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.snippet.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${widget.snippet.command})',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: AppColors.accentCyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
