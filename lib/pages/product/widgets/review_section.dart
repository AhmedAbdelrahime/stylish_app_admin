import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/product/data/review_service.dart';
import 'package:hungry/pages/product/model/review_model.dart';

class ReviewSection extends StatefulWidget {
  const ReviewSection({super.key, required this.productId});

  final String productId;

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  late Future<List<ReviewModel>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = ReviewService().getReviewsForProduct(widget.productId);
  }

  @override
  void didUpdateWidget(covariant ReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      setState(() {
        _reviewsFuture = ReviewService().getReviewsForProduct(widget.productId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReviewModel>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final reviews = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Reviews',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${reviews.length} recent comments from real shoppers.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.hintColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              ...reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewCard(review: review),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewModel review;

  String get _formattedDate {
    final date = review.createdAt;
    if (date == null) return 'Recent review';

    final monthNames = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final initial = review.reviewerName.trim().isEmpty
        ? 'C'
        : review.reviewerName.trim().characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.redColor.withValues(alpha: 0.12),
            foregroundColor: AppColors.redColor,
            backgroundImage: review.reviewerImageUrl?.isNotEmpty == true
                ? NetworkImage(review.reviewerImageUrl!)
                : null,
            child: review.reviewerImageUrl?.isNotEmpty == true
                ? null
                : Text(
                    initial,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.reviewerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blackColor,
                        ),
                      ),
                    ),
                    Text(
                      _formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RatingBarIndicator(
                  rating: review.rating.clamp(0, 5),
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star_rounded, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 14,
                ),
                const SizedBox(height: 8),
                Text(
                  review.comment,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.hintColor,
                    height: 1.45,
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
