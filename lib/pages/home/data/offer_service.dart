import 'package:hungry/pages/home/models/offer_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfferService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<OfferesModel>> getOffers() async {
    final results = await Future.wait<dynamic>([
      _safeSelectOffers(),
      _safeSelectBanners(),
    ]);

    final offersData = results[0] as List<dynamic>;
    final bannersData = results[1] as List<dynamic>;

    final banners = bannersData
        .whereType<Map<String, dynamic>>()
        .where((item) => item['is_active'] == true)
        .map(
          (item) => OfferesModel(
            id: item['id'].toString(),
            imageUrl: (item['image_url'] ?? '') as String,
            title: item['title'] as String?,
          ),
        );

    final offers = offersData
        .whereType<Map<String, dynamic>>()
        .map(OfferesModel.fromJson);

    return [...banners, ...offers];
  }

  Future<List<dynamic>> _safeSelectOffers() async {
    try {
      return await _supabase.from('offers').select().order('created_at');
    } catch (_) {
      return const [];
    }
  }

  Future<List<dynamic>> _safeSelectBanners() async {
    try {
      return await _supabase
          .from('banners')
          .select('id, title, image_url, is_active, sort_order, created_at')
          .order('sort_order')
          .order('created_at', ascending: false);
    } catch (_) {
      return const [];
    }
  }
}
