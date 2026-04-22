import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/pages/home/data/category_service.dart';
import 'package:hungry/pages/home/models/category_model.dart';

import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryService categoryService;

  CategoryCubit(this.categoryService) : super(CategoryInitial());

  List<CategoryModel> categories = [];

  Future<void> loadCategories() async {
    emit(CategoryLoading());

    try {
      categories = await categoryService.getCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}
