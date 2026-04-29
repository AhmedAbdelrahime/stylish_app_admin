import 'package:hungry/pages/settings/data/user_model.dart';

class AdminOrderItemModel {
  const AdminOrderItemModel({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    this.productTitle,
    this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    this.selectedSize,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final String? productId;
  final String productName;
  final String? productTitle;
  final String? productImageUrl;
  final double unitPrice;
  final int quantity;
  final int? selectedSize;
  final DateTime? createdAt;

  double get lineTotal => unitPrice * quantity;

  factory AdminOrderItemModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderItemModel(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      productId: json['product_id']?.toString(),
      productName: (json['product_name'] ?? '') as String,
      productTitle: json['product_title'] as String?,
      productImageUrl: json['product_image_url'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      selectedSize: (json['selected_size'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class AdminOrderModel {
  const AdminOrderModel({
    required this.id,
    this.userId,
    required this.status,
    required this.paymentStatus,
    required this.deliveryStatus,
    required this.subtotal,
    required this.shippingFee,
    required this.discountAmount,
    required this.totalAmount,
    required this.currency,
    this.shippingAddress,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.items = const [],
  });

  final String id;
  final String? userId;
  final String status;
  final String paymentStatus;
  final String deliveryStatus;
  final double subtotal;
  final double shippingFee;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final String? shippingAddress;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserModel? user;
  final List<AdminOrderItemModel> items;

  bool get hasCustomer => user != null;
  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  String get displayCustomerName {
    final name = user?.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final email = user?.email.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    return 'Guest customer';
  }

  String get orderCode => '#${id.substring(0, 8).toUpperCase()}';

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['profile'];
    final itemsJson = json['order_items'];

    return AdminOrderModel(
      id: json['id'].toString(),
      userId: json['user_id']?.toString(),
      status: (json['status'] ?? 'pending') as String,
      paymentStatus: (json['payment_status'] ?? 'pending') as String,
      deliveryStatus: (json['delivery_status'] ?? 'pending') as String,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'USD') as String,
      shippingAddress: json['shipping_address'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : null,
      items: itemsJson is List
          ? itemsJson
                .whereType<Map<String, dynamic>>()
                .map(AdminOrderItemModel.fromJson)
                .toList()
          : const [],
    );
  }
}
