import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/home/logic/category/cubit/category_cubit.dart';
import 'package:hungry/pages/home/logic/category/cubit/category_state.dart';

class CatSection extends StatelessWidget {
  const CatSection({super.key});

  void _openCategorySearch(
    BuildContext context,
    String categoryId,
    String categoryName,
  ) {}

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const SizedBox(
            height: 110,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.redColor),
            ),
          );
        }

        if (state is CategoryError) {
          return SizedBox(
            height: 110,
            child: Center(
              child: Text(state.message, textAlign: TextAlign.center),
            ),
          );
        }

        if (state is CategoryLoaded) {
          if (state.categories.isEmpty) {
            return const SizedBox(
              height: 110,
              child: Center(child: Text('No categories found')),
            );
          }

          return SizedBox(
            height: 110,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: state.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = state.categories[index];

                return GestureDetector(
                  onTap: () =>
                      _openCategorySearch(context, category.id, category.name),
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        Container(
                          height: 68,
                          width: 68,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              category.imageUrl ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.category,
                                color: AppColors.redColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox(
          height: 110,
          child: Center(child: Text('Loading categories...')),
        );
      },
    );
  }
}
