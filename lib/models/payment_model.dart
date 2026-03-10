import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String orderId;
  final bool isPaid;
  final double amountPaid;
  final double totalAmount;
  final DateTime? paymentDate;
  final String notes;

  PaymentModel({
    required this.orderId,
    required this.isPaid,
    required this.amountPaid,
    required this.totalAmount,
    this.paymentDate,
    this.notes = '',
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      orderId: doc.id,
      isPaid: data['isPaid'] ?? false,
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: (data['paymentDate'] as Timestamp?)?.toDate(),
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'isPaid': isPaid,
        'amountPaid': amountPaid,
        'totalAmount': totalAmount,
        'paymentDate': paymentDate != null
            ? Timestamp.fromDate(paymentDate!)
            : null,
        'notes': notes,
      };
}
