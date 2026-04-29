import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/core/realtime/supabase_realtime_reloader.dart';
import 'package:hungry/pages/home/data/offer_service.dart';
import 'package:hungry/pages/home/models/offer_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'offer_state.dart';

class OfferCubit extends Cubit<OfferState> {
  final OfferService offerService;
  SupabaseRealtimeReloader? _realtimeReloader;

  OfferCubit(this.offerService) : super(OfferInitial()) {
    _setupRealtime();
  }

  List<OfferesModel> offers = [];

  void _setupRealtime() {
    _realtimeReloader = SupabaseRealtimeReloader(
      supabase: Supabase.instance.client,
      channelName: 'store-offers-${DateTime.now().microsecondsSinceEpoch}',
      tables: const ['offers', 'banners'],
      onReload: () async {
        try {
          await loadOffers(showLoading: false);
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

  Future<void> loadOffers({bool showLoading = true}) async {
    if (showLoading || state is OfferInitial) {
      emit(OfferLoading());
    }

    try {
      offers = await offerService.getOffers();
      emit(OfferLoaded(offers));
    } catch (e) {
      if (showLoading || offers.isEmpty) {
        emit(OfferError(e.toString()));
      }
    }
  }
}
