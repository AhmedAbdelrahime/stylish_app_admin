class AdminOfferModel {
  const AdminOfferModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.createdAt,
  });

  final String id;
  final String imageUrl;
  final String? title;
  final DateTime? createdAt;

  factory AdminOfferModel.fromJson(Map<String, dynamic> json) {
    return AdminOfferModel(
      id: json['id'].toString(),
      imageUrl: (json['image_url'] ?? '') as String,
      title: json['title'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
