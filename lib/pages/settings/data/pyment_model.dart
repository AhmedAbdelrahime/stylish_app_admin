class PaymentMethod {
  final String userId;
  final String? id;
  final String holderName;
  final String last4;
  final String brand;
  final int? expMonth; // nullable
  final int? expYear; // nullable

  PaymentMethod({
    required this.userId,
    this.id,
    required this.holderName,
    required this.last4,
    required this.brand,
    this.expMonth,
    this.expYear,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      userId: json['user_id'] as String,
      id: json['id'] as String,
      holderName: json['holder_name'] as String,
      last4: json['last4'] as String,
      brand: json['brand'] as String,
      expMonth: json['exp_month'] as int?,
      expYear: json['exp_year'] as int?,
    );
  }
  // Map<String, dynamic> toJson() {
  //   return {
  //     'user_id': userId,
  //     'id': id,
  //     'holder_name': holderName,
  //     'last4': last4,
  //     'brand': brand,
  //     'exp_month': expMonth,
  //     'exp_year': expYear,
  //   };
  // }
}

class AddPaymentMethodDto {
  final String? userId;
  final String holderName;
  final String last4;
  final String brand;
  final int? expMonth;
  final int? expYear;

  AddPaymentMethodDto({
    this.userId,
    required this.holderName,
    required this.last4,
    required this.brand,
    this.expMonth,
    this.expYear,
  });

  Map<String, dynamic> toJson() => {
    'holder_name': holderName,
    'last4': last4,
    'brand': brand,
    'exp_month': expMonth,
    'exp_year': expYear,
  };
}
