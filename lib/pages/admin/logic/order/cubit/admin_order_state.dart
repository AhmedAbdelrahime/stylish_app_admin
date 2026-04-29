import 'package:equatable/equatable.dart';
import 'package:hungry/pages/admin/data/admin_order_model.dart';

class AdminOrderState extends Equatable {
  const AdminOrderState({
    this.orders = const [],
    this.isLoading = true,
    this.updatingOrderId,
  });

  final List<AdminOrderModel> orders;
  final bool isLoading;
  final String? updatingOrderId;

  AdminOrderState copyWith({
    List<AdminOrderModel>? orders,
    bool? isLoading,
    Object? updatingOrderId = _sentinel,
  }) {
    return AdminOrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      updatingOrderId: updatingOrderId == _sentinel
          ? this.updatingOrderId
          : updatingOrderId as String?,
    );
  }

  @override
  List<Object?> get props => [orders, isLoading, updatingOrderId];
}

const Object _sentinel = Object();
