import 'package:flutter/foundation.dart';
import 'package:hungry/pages/product/model/review_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ReviewModel>> getReviewsForProduct(String productId) async {
    try {
      final reviews = await _fetchReviews(
        table: 'reviews',
        productId: productId,
      );
      if (reviews.isNotEmpty) {
        return reviews;
      }

      return await _fetchReviews(
        table: 'product_reviews',
        productId: productId,
      );
    } catch (error) {
      debugPrint('Error fetching reviews: $error');
      return [];
    }
  }

  Future<List<ReviewModel>> _fetchReviews({
    required String table,
    required String productId,
  }) async {
    final List<dynamic> data = await _supabase
        .from(table)
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false)
        .limit(5);

    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(ReviewModel.fromJson)
        .where((review) => review.comment.trim().isNotEmpty)
        .toList();
  }
}
