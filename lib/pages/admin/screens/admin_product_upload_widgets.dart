part of 'admin_product_screen.dart';

class _ProductImageUploadCard extends StatelessWidget {
  const _ProductImageUploadCard({
    required this.bytes,
    required this.fileName,
    required this.isPickingImage,
    required this.title,
    required this.description,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final Uint8List? bytes;
  final String? fileName;
  final bool isPickingImage;
  final String title;
  final String description;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grayColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.white,
                child: hasImage
                    ? Image.memory(bytes!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 42,
                            color: AppColors.redColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blackColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.hintColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasImage
                      ? (fileName ?? 'Selected image')
                      : 'No image selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.hintColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (hasImage)
                TextButton(
                  onPressed: onRemoveImage,
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      color: AppColors.redColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: isPickingImage ? null : onPickImage,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blackColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isPickingImage
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(hasImage ? 'Change' : 'Choose Image'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductGalleryUploadCard extends StatelessWidget {
  const _ProductGalleryUploadCard({
    required this.existingUrls,
    required this.selectedBytes,
    required this.selectedNames,
    required this.isPickingImages,
    required this.onPickImages,
    required this.onRemoveExisting,
    required this.onRemoveSelected,
  });

  final List<String> existingUrls;
  final List<Uint8List> selectedBytes;
  final List<String> selectedNames;
  final bool isPickingImages;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    final hasImages = existingUrls.isNotEmpty || selectedBytes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grayColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gallery images',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload multiple detail shots instead of pasting raw gallery URLs.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 14),
          if (hasImages)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < existingUrls.length; i++)
                  _GalleryImageChip(
                    label: 'Saved image ${i + 1}',
                    image: Image.network(
                      existingUrls[i],
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.grayColor,
                        ),
                      ),
                    ),
                    onRemove: () => onRemoveExisting(i),
                  ),
                for (var i = 0; i < selectedBytes.length; i++)
                  _GalleryImageChip(
                    label: selectedNames[i],
                    image: Image.memory(selectedBytes[i], fit: BoxFit.cover),
                    onRemove: () => onRemoveSelected(i),
                  ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'No gallery images selected yet.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.hintColor,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isPickingImages ? null : onPickImages,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blackColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isPickingImages
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.collections_outlined),
              label: const Text('Upload Gallery Images'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryImageChip extends StatelessWidget {
  const _GalleryImageChip({
    required this.label,
    required this.image,
    required this.onRemove,
  });

  final String label;
  final Widget image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(height: 92, width: 118, child: image),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.hintColor,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRemove,
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: AppColors.redColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
