class OfferesModel {
  final String id;
  final String imageUrl;
  final String? title;

  OfferesModel({
    required this.id,
    required this.imageUrl,
    this.title,
  });

  factory OfferesModel.fromJson(Map<String, dynamic> json) {
    return OfferesModel(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      title: json['title'] as String?,
    );
  }
}
