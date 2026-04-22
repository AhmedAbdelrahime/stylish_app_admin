class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isVisible;
  final int sortOrder;

  CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isVisible = true,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: (json['name'] ?? '') as String,
      imageUrl: json['image_url'] as String?,
      isVisible: json['is_visible'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
