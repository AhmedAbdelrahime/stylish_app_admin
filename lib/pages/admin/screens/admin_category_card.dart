part of 'admin_category_screen.dart';

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.linkedProductsCount,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleVisibility,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final CategoryModel category;
  final int linkedProductsCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: AspectRatio(
              aspectRatio: 1.7,
              child: Image.network(
                category.imageUrl ?? '',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primaryColor,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.grayColor,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.imageUrl ?? 'No image available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminTag(
                      label:
                          '$linkedProductsCount product${linkedProductsCount == 1 ? '' : 's'}',
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.blackColor,
                      isCompact: true,
                    ),
                    AdminTag(
                      label: category.isVisible ? 'Visible' : 'Hidden',
                      backgroundColor: category.isVisible
                          ? const Color(0xFFE8F7ED)
                          : const Color(0xFFFFE4E6),
                      foregroundColor: category.isVisible
                          ? const Color(0xFF1E8E5A)
                          : Colors.red,
                      isCompact: true,
                    ),
                    AdminTag(
                      label: 'Sort ${category.sortOrder}',
                      isCompact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      IconButton(
                        onPressed: onMoveUp,
                        tooltip: 'Move up',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: const Icon(Icons.arrow_upward_rounded, size: 19),
                      ),
                      IconButton(
                        onPressed: onMoveDown,
                        tooltip: 'Move down',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 19,
                        ),
                      ),
                      IconButton(
                        onPressed: onToggleVisibility,
                        tooltip: category.isVisible ? 'Hide' : 'Show',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: Icon(
                          category.isVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 19,
                        ),
                      ),
                      IconButton(
                        onPressed: onEdit,
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        tooltip: 'Delete',
                        color: Colors.red,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 19),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
