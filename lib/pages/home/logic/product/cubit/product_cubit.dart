import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/core/realtime/supabase_realtime_reloader.dart';
import 'package:hungry/pages/home/data/product_service.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductService productService;
  SupabaseRealtimeReloader? _realtimeReloader;

  ProductCubit(this.productService) : super(ProductInitial()) {
    _setupRealtime();
  }

  List<ProductModel> products = [];

  void _setupRealtime() {
    _realtimeReloader = SupabaseRealtimeReloader(
      supabase: Supabase.instance.client,
      channelName: 'store-products-${DateTime.now().microsecondsSinceEpoch}',
      tables: const ['products'],
      onReload: () async {
        try {
          await loadProducts(showLoading: false);
        } catch (_) {
          // Keep storefront realtime resilient.
        }
      },
    );
  }

  @override
  Future<void> close() {
    _realtimeReloader?.dispose();
    return super.close();
  }

  Future<void> loadProducts({bool showLoading = true}) async {
    if (showLoading || state is ProductInitial) {
      emit(ProductLoading());
    }

    try {
      products = await productService.getProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      if (showLoading || products.isEmpty) {
        emit(ProductError(e.toString()));
      }
    }
  }
}
