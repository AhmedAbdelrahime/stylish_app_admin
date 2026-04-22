import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/pages/home/data/product_service.dart';
import 'package:hungry/pages/home/models/product_model.dart';

import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductService productService;

  ProductCubit(this.productService) : super(ProductInitial());

  List<ProductModel> products = [];

  Future<void> loadProducts() async {
    emit(ProductLoading());

    try {
      products = await productService.getProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
