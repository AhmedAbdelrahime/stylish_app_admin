// ignore_for_file: invalid_use_of_protected_member

part of 'admin_order_screen.dart';

extension _AdminOrderDataActions on _AdminOrderViewState {
  Future<void> _loadOrders() async {
    try {
      await context.read<AdminOrderCubit>().loadOrders();
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _updateOrderStatus({
    required AdminOrderModel order,
    String? status,
    String? paymentStatus,
    String? deliveryStatus,
  }) async {
    final orderCubit = context.read<AdminOrderCubit>();
    try {
      await orderCubit.updateOrderStatus(
        order: order,
        status: status,
        paymentStatus: paymentStatus,
        deliveryStatus: deliveryStatus,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: '${order.orderCode} updated successfully.',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    }
  }
}
