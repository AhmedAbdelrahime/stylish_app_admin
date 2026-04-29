part of 'admin_category_screen.dart';

class _ImageUploadCard extends StatelessWidget {
  const _ImageUploadCard({
    required this.bytes,
    required this.fileName,
    required this.isPickingImage,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final Uint8List? bytes;
  final String? fileName;
  final bool isPickingImage;
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
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 42,
                            color: AppColors.redColor,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Upload category image',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blackColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Best for web admin: clean artwork, square or landscape.',
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
