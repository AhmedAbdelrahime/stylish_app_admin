part of 'admin_product_screen.dart';

class _ProductImportPreview {
  const _ProductImportPreview({
    required this.fileName,
    required this.rows,
    required this.invalidRowCount,
  });

  final String fileName;
  final List<AdminProductImportRow> rows;
  final int invalidRowCount;

  int get totalRowCount => rows.length;

  int get readyToImportCount =>
      rows.where((row) => row.isValid && !row.hasMissingCategory).length;

  int get rowsWithMissingCategoriesCount =>
      rows.where((row) => row.isValid && row.hasMissingCategory).length;

  List<String> get missingCategoryLabels {
    final labels = <String>{};
    for (final row in rows) {
      if (row.isValid && row.hasMissingCategory) {
        labels.add(row.missingCategoryLabel);
      }
    }
    final sorted = labels.toList()..sort();
    return sorted;
  }
}

class _ProductImportPreviewCard extends StatelessWidget {
  const _ProductImportPreviewCard({
    required this.preview,
    required this.isBusy,
    required this.onCreateCategories,
    required this.onImportAsDraft,
    required this.onSkipRows,
    required this.onCancel,
  });

  final _ProductImportPreview preview;
  final bool isBusy;
  final VoidCallback onCreateCategories;
  final VoidCallback onImportAsDraft;
  final VoidCallback onSkipRows;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sheet audit',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Checked ${preview.totalRowCount} row${preview.totalRowCount == 1 ? '' : 's'}. ${preview.readyToImportCount} ${preview.readyToImportCount == 1 ? 'row is' : 'rows are'} ready now, ${preview.rowsWithMissingCategoriesCount} ${preview.rowsWithMissingCategoriesCount == 1 ? 'row has' : 'rows have'} missing categories, and ${preview.invalidRowCount} ${preview.invalidRowCount == 1 ? 'row is' : 'rows are'} invalid.',
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          if (preview.missingCategoryLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Missing categories: ${preview.missingCategoryLabels.join(', ')}',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: isBusy ? null : onCreateCategories,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blackColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Create missing categories'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onImportAsDraft,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Import missing as draft'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onSkipRows,
                icon: const Icon(Icons.skip_next_outlined),
                label: const Text('Skip missing rows'),
              ),
              TextButton.icon(
                onPressed: isBusy ? null : onCancel,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel review'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
