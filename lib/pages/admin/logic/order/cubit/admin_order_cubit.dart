import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/core/realtime/supabase_realtime_reloader.dart';
import 'package:hungry/pages/admin/data/admin_order_model.dart';
import 'package:hungry/pages/admin/data/admin_order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_order_state.dart';

class AdminOrderCubit extends Cubit<AdminOrderState> {
  AdminOrderCubit({AdminOrderService? orderService})
    : _orderService = orderService ?? AdminOrderService(),
      super(const AdminOrderState()) {
    _setupRealtime();
  }

  final AdminOrderService _orderService;
  SupabaseRealtimeReloader? _realtimeReloader;

  void _setupRealtime() {
    _realtimeReloader = SupabaseRealtimeReloader(
      supabase: Supabase.instance.client,
      channelName: 'admin-orders-${DateTime.now().microsecondsSinceEpoch}',
      tables: const ['orders', 'order_items', 'profiles'],
      onReload: () async {
        if (state.updatingOrderId != null) {
          return;
        }
        try {
          await loadOrders(showLoading: false);
        } catch (_) {
          // Keep realtime resilient.
        }
      },
    );
  }

  @override
  Future<void> close() {
    _realtimeReloader?.dispose();
    return super.close();
  }

  Future<void> loadOrders({bool showLoading = true}) async {
    if (isClosed) return;

    if (showLoading) {
      emit(state.copyWith(isLoading: true));
    }

    try {
      final orders = await _orderService.getOrders();
      if (isClosed) return;
      emit(state.copyWith(orders: orders, isLoading: false));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false));
      }
      rethrow;
    }
  }

  Future<void> updateOrderStatus({
    required AdminOrderModel order,
    String? status,
    String? paymentStatus,
    String? deliveryStatus,
  }) async {
    emit(state.copyWith(updatingOrderId: order.id));

    try {
      await _orderService.updateOrderStatuses(
        orderId: order.id,
        status: status,
        paymentStatus: paymentStatus,
        deliveryStatus: deliveryStatus,
      );
      await loadOrders(showLoading: false);
    } finally {
      emit(state.copyWith(updatingOrderId: null));
    }
  }
}
