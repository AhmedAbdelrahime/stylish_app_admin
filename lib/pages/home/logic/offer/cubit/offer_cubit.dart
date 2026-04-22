import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/pages/home/data/offer_service.dart';
import 'package:hungry/pages/home/models/offeres_model.dart';

import 'offer_state.dart';

class OfferCubit extends Cubit<OfferState> {
  final OfferService offerService;

  OfferCubit(this.offerService) : super(OfferInitial());

  List<OfferesModel> offers = [];

  Future<void> loadOffers() async {
    emit(OfferLoading());

    try {
      offers = await offerService.getOffers();
      emit(OfferLoaded(offers));
    } catch (e) {
      emit(OfferError(e.toString()));
    }
  }
}
