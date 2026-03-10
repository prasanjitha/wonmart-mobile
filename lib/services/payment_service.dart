import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _payments => _db.collection('payments');

  Future<void> createPaymentRecord(PaymentModel payment) async {
    await _payments.doc(payment.orderId).set(payment.toMap());
  }

  Future<PaymentModel?> getPayment(String orderId) async {
    final doc = await _payments.doc(orderId).get();
    if (!doc.exists) return null;
    return PaymentModel.fromFirestore(doc);
  }

  Stream<PaymentModel?> watchPayment(String orderId) {
    return _payments.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PaymentModel.fromFirestore(doc);
    });
  }

  Future<void> markAsPaid({
    required String orderId,
    required double amountPaid,
    String notes = '',
  }) async {
    await _payments.doc(orderId).update({
      'isPaid': true,
      'amountPaid': amountPaid,
      'paymentDate': FieldValue.serverTimestamp(),
      'notes': notes,
    });
  }

  Future<void> deletePaymentRecord(String orderId) async {
    await _payments.doc(orderId).delete();
  }

  Stream<List<PaymentModel>> watchAgentPayments(List<String> orderIds) {
    if (orderIds.isEmpty) {
      return Stream.value([]);
    }
    return _payments
        .where(FieldPath.documentId, whereIn: orderIds)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PaymentModel.fromFirestore(d)).toList());
  }
}
