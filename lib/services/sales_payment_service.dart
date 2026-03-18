import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sales_payment_model.dart';
import '../models/sales_record_model.dart';

class SalesPaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> addPayment(
    SalesPaymentModel payment,
    SalesRecordModel salesRecord,
  ) async {
    // 1. Find existing payment document by salesRecordId
    final existingPayments = await _db
        .collection('all_sale_payments')
        .where('salesRecordId', isEqualTo: salesRecord.id)
        .limit(1)
        .get();

    String paymentId;
    if (existingPayments.docs.isNotEmpty) {
      paymentId = existingPayments.docs.first.id;
    } else {
      // Fallback if no payment record exists
      final newDocRef = _db.collection('all_sale_payments').doc();
      paymentId = newDocRef.id;
    }

    final batch = _db.batch();

    final newPaidAmount = salesRecord.paidAmount + payment.payAmount;
    final newStatus =
        (newPaidAmount + salesRecord.totalReturnAmount) >=
            salesRecord.totalAmount
        ? 'completed'
        : 'partial';

    // Update Payment docs
    final paymentUpdateData = {
      'salesRecordId': salesRecord.id,
      'payAmount': payment.payAmount,
      'paidAmount': newPaidAmount,
      'paymentStatus': newStatus,
      'status': newStatus,
      'paymentType': payment.paymentType,
      'updatedAt': FieldValue.serverTimestamp(),
      'agentId': payment.agentId,
      'shopId': payment.shopId,
      'shopName': payment.shopName,
      'agentName': payment.agentName,
      'totalAmount': salesRecord.totalAmount,
    };

    // Update all_sale_payments
    final rootRef = _db.collection('all_sale_payments').doc(paymentId);
    batch.set(rootRef, paymentUpdateData, SetOptions(merge: true));

    // Update agent's sales_payment
    final agentPaymentRef = _db
        .collection('agents')
        .doc(payment.agentId)
        .collection('sales_payment')
        .doc(paymentId);
    batch.set(agentPaymentRef, paymentUpdateData, SetOptions(merge: true));

    // Update shop's sales_payment
    final shopPaymentRef = _db
        .collection('agents')
        .doc(payment.agentId)
        .collection('shops')
        .doc(payment.shopId)
        .collection('sales_payment')
        .doc(paymentId);
    batch.set(shopPaymentRef, paymentUpdateData, SetOptions(merge: true));

    // Update Sales Record status in both locations (Agent & Shop)
    final salesUpdateData = {
      'paidAmount': newPaidAmount,
      'paymentStatus': newStatus,
    };

    // Agent's sales_records
    final agentSalesRef = _db
        .collection('agents')
        .doc(payment.agentId)
        .collection('sales_records')
        .doc(salesRecord.id);
    batch.update(agentSalesRef, salesUpdateData);

    // Shop's sales_records
    final shopSalesRef = _db
        .collection('agents')
        .doc(payment.agentId)
        .collection('shops')
        .doc(payment.shopId)
        .collection('sales_records')
        .doc(salesRecord.id);
    batch.update(shopSalesRef, salesUpdateData);

    // Update daily collection aggregate
    final now = DateTime.now();
    final dateString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final dailyRef = _db
        .collection('agents')
        .doc(payment.agentId)
        .collection('daily_collections')
        .doc(dateString);

    batch.set(dailyRef, {
      'date': dateString,
      'collectedAmount': FieldValue.increment(payment.payAmount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return paymentId;
  }

  Future<double> getTodayTotalPayments(String agentId) async {
    final now = DateTime.now();
    final dateString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final doc = await _db
        .collection('agents')
        .doc(agentId)
        .collection('daily_collections')
        .doc(dateString)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['collectedAmount'] ?? 0.0).toDouble();
    }
    return 0.0;
  }

  Stream<double> watchTodayTotalPayments(String agentId) {
    final now = DateTime.now();
    final dateString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return _db
        .collection('agents')
        .doc(agentId)
        .collection('daily_collections')
        .doc(dateString)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['collectedAmount'] ?? 0.0).toDouble();
          }
          return 0.0;
        });
  }
}
