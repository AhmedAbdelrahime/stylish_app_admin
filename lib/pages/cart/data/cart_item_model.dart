import 'package:hungry/pages/home/models/product_model.dart';

class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.productTitle,
    required this.imagePath,
    required this.price,
    required this.quantity,
    required this.stockQuantity,
    this.originalPrice,
    this.color,
    this.size,
    this.rating = 0,
  });

  final String id;
  final String productId;
  final String name;
  final String productTitle;
  final String imagePath;
  final double price;
  final int quantity;
  final int stockQuantity;
  final double? originalPrice;
  final String? color;
  final int? size;
  final double rating;

  factory CartItemModel.fromProduct({
    required ProductModel product,
    required int quantity,
    int? selectedSize,
    String? color,
  }) {
    return CartItemModel(
      id: storageId(product.id, selectedSize),
      productId: product.id,
      name: product.name,
      productTitle: product.title,
      imagePath: product.primaryImage,
      price: product.effectivePrice,
      quantity: quantity,
      stockQuantity: product.stockQuantity,
      originalPrice: product.hasSale ? product.price : null,
      color: color,
      size: selectedSize,
      rating: product.rating,
    );
  }

  static String storageId(String productId, int? size) {
    return '$productId::${size ?? 'default'}';
  }

  bool get hasDiscount =>
      originalPrice != null && originalPrice! > 0 && originalPrice! > price;

  bool get isInStock => stockQuantity > 0;

  bool get isLowStock => isInStock && stockQuantity <= 3;

  double get lineTotal => price * quantity;

  int get discountPercentage {
    if (!hasDiscount) return 0;

    final discount = ((originalPrice! - price) / originalPrice!) * 100;
    return discount.round();
  }
}
