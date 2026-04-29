import 'package:equatable/equatable.dart';
import 'package:hungry/pages/home/models/category_model.dart';
import 'package:hungry/pages/home/models/product_model.dart';

class AdminProductState extends Equatable {
  const AdminProductState({
    this.products = const [],
    this.categories = const [],
    this.selectedProductIds = const <String>{},
    this.isLoading = true,
    this.isSaving = false,
    this.isDeleting = false,
    this.isBulkUpdating = false,
  });

  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final Set<String> selectedProductIds;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final bool isBulkUpdating;

  AdminProductState copyWith({
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    Set<String>? selectedProductIds,
    bool? isLoading,
    bool? isSaving,
    bool? isDeleting,
    bool? isBulkUpdating,
  }) {
    return AdminProductState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedProductIds: selectedProductIds ?? this.selectedProductIds,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      isBulkUpdating: isBulkUpdating ?? this.isBulkUpdating,
    );
  }

  @override
  List<Object?> get props => [
    products,
    categories,
    isLoading,
    isSaving,
    isDeleting,
    isBulkUpdating,
    _selectedIdsKey,
  ];

  String get _selectedIdsKey {
    final ids = selectedProductIds.toList()..sort();
    return ids.join('|');
  }
}
