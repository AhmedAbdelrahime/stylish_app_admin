class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.productId,
    required this.reviewerName,
    required this.comment,
    required this.rating,
    this.createdAt,
    this.reviewerImageUrl,
  });

  final String id;
  final String productId;
  final String reviewerName;
  final String comment;
  final double rating;
  final DateTime? createdAt;
  final String? reviewerImageUrl;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'].toString(),
      productId: (json['product_id'] ?? '').toString(),
      reviewerName:
          (json['reviewer_name'] ??
                  json['user_name'] ??
                  json['full_name'] ??
                  json['name'] ??
                  'Customer')
              .toString(),
      comment:
          (json['comment'] ??
                  json['review_text'] ??
                  json['text'] ??
                  json['body'] ??
                  '')
              .toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      reviewerImageUrl:
          (json['reviewer_image_url'] ?? json['image'] ?? json['avatar_url'])
              ?.toString(),
    );
  }
}
