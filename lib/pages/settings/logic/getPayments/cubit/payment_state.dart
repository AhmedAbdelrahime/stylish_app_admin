import 'package:equatable/equatable.dart';
import 'package:hungry/pages/settings/data/pyment_model.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentLoaded extends PaymentState {
  final List<PaymentMethod> methods;

  const PaymentLoaded(this.methods);

  @override
  List<Object?> get props => [methods];
}

class PaymentDeleting extends PaymentState {
  final List<PaymentMethod> methods;
  final String deletingId;

  const PaymentDeleting({
    required this.methods,
    required this.deletingId,
  });

  @override
  List<Object?> get props => [methods, deletingId];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}