import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/core/realtime/supabase_realtime_reloader.dart';
import 'package:hungry/pages/home/data/category_service.dart';
import 'package:hungry/pages/home/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryService categoryService;
  SupabaseRealtimeReloader? _realtimeReloader;

  CategoryCubit(this.categoryService) : super(CategoryInitial()) {
    _setupRealtime();
  }

  List<CategoryModel> categories = [];

  void _setupRealtime() {
    _realtimeReloader = SupabaseRealtimeReloader(
      supabase: Supabase.instance.client,
      channelName: 'store-categories-${DateTime.now().microsecondsSinceEpoch}',
      tables: const ['categories'],
      onReload: () async {
        try {
          await loadCategories(showLoading: false);
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

  Future<void> loadCategories({bool showLoading = true}) async {
    if (showLoading || state is CategoryInitial) {
      emit(CategoryLoading());
    }

    try {
      categories = await categoryService.getCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      if (showLoading || categories.isEmpty) {
        emit(CategoryError(e.toString()));
      }
    }
  }
}
