import 'package:equatable/equatable.dart';
import 'package:hungry/pages/home/models/offeres_model.dart';

abstract class OfferState extends Equatable {
  const OfferState();

  @override
  List<Object?> get props => [];
}

class OfferInitial extends OfferState {}

class OfferLoading extends OfferState {}

class OfferLoaded extends OfferState {
  final List<OfferesModel> offers;

  const OfferLoaded(this.offers);

  @override
  List<Object?> get props => [offers];
}

class OfferError extends OfferState {
  final String message;

  const OfferError(this.message);

  @override
  List<Object?> get props => [message];
}
