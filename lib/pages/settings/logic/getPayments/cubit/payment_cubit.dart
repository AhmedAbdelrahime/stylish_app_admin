import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/pages/settings/data/payment_service.dart';
import 'package:hungry/pages/settings/data/pyment_model.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentService service;

  PaymentCubit(this.service) : super(PaymentInitial());

  List<PaymentMethod> methods = [];

  Future<void> loadPayments() async {

    emit(PaymentLoading());
    
    try {
      methods = await service.getPaymentMethods();
      emit(PaymentLoaded(methods));
    } catch (e) {
      emit(PaymentError('Failed to load payment methods'));
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      emit(PaymentDeleting(methods: methods, deletingId: id));

      await service.deletePaymentMethod(id);

      methods.removeWhere((m) => m.id == id);

      emit(PaymentLoaded(List.from(methods)));
    } catch (e) {
      emit(PaymentError('Failed to delete card'));
      emit(PaymentLoaded(methods));
    }
  }
}