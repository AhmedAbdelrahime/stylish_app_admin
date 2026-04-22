import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProudectImages extends StatefulWidget {
  const ProudectImages({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProudectImages> createState() => _ProudectImagesState();
}

class _ProudectImagesState extends State<ProudectImages> {
  late final PageController _pageController;
  int _activeIndex = 0;

  List<String> get _images {
    final images = widget.product.imageUrls.isEmpty
        ? [widget.product.primaryImage]
        : widget.product.imageUrls;

    return images.where((image) => image.isNotEmpty).toList();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openPreview(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _GalleryPreviewPage(images: images, initialIndex: initialIndex),
      ),
    );
  }

  void _goToImage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;

    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _activeIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => _openPreview(images, index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: _ProductImage(imageUrl: images[index]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Gap(14),
        AnimatedSmoothIndicator(
          activeIndex: _activeIndex,
          count: images.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 9,
            dotWidth: 9,
            expansionFactor: 2.5,
            activeDotColor: AppColors.redColor,
            dotColor: AppColors.grayColor,
          ),
        ),
        if (images.length > 1) ...[
          const Gap(16),
          SizedBox(
            height: 74,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final isActive = index == _activeIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeIndex = index;
                    });
                    _goToImage(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 74,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isActive
                            ? AppColors.redColor
                            : Colors.transparent,
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _ProductImage(imageUrl: images[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Image.asset('assets/images/cat.png', fit: BoxFit.cover),
    );
  }
}

class _GalleryPreviewPage extends StatefulWidget {
  const _GalleryPreviewPage({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_GalleryPreviewPage> createState() => _GalleryPreviewPageState();
}

class _GalleryPreviewPageState extends State<_GalleryPreviewPage> {
  late final PageController _previewController;
  late int _activeIndex;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialIndex;
    _previewController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('${_activeIndex + 1}/${widget.images.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _previewController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _activeIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: _ProductImage(imageUrl: widget.images[index]),
                  ),
                );
              },
            ),
          ),
          if (widget.images.length > 1)
            SizedBox(
              height: 92,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isActive = index == _activeIndex;

                  return GestureDetector(
                    onTap: () {
                      _previewController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 70,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? Colors.white : Colors.transparent,
                          width: 1.6,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _ProductImage(imageUrl: widget.images[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
