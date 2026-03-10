import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sales_order_model.dart';
import 'inventory_service.dart';
import 'payment_service.dart';
import '../models/payment_model.dart';

class SalesOrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final InventoryService _inventoryService = InventoryService();
  final PaymentService _paymentService = PaymentService();

  CollectionReference get _orders => _db.collection('sales_orders');

  Stream<List<SalesOrderModel>> watchAgentOrders(String agentId) {
    return _orders
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SalesOrderModel.fromFirestore(d)).toList());
  }

  Future<List<SalesOrderModel>> getAgentOrders(String agentId) async {
    final snap = await _orders
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => SalesOrderModel.fromFirestore(d)).toList();
  }

  /// Create a new sales order (in draft or issued state)
  Future<String> createOrder(SalesOrderModel order) async {
    final doc = await _orders.add(order.toMap());
    return doc.id;
  }

  /// Issue an order: set status = 'issued', deduct stock, create payment record
  Future<void> issueOrder(SalesOrderModel order) async {
    // 1. Update order status
    await _orders.doc(order.id).update({'status': 'issued'});

    // 2. Deduct from inventory
    final deductions = <String, int>{};
    for (final item in order.items) {
      if (item.productId.isNotEmpty) {
        deductions[item.productId] =
            (deductions[item.productId] ?? 0) + item.quantity;
      }
    }
    if (deductions.isNotEmpty) {
      await _inventoryService.deductStock(order.agentId, deductions);
    }

    // 3. Create payment record as Credit by default
    await _paymentService.createPaymentRecord(PaymentModel(
      orderId: order.id,
      isPaid: false,
      amountPaid: 0,
      totalAmount: order.total,
    ));
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    await _orders.doc(orderId).update(data);
  }

  Future<void> deleteOrder(String orderId) async {
    await _orders.doc(orderId).delete();
    await _paymentService.deletePaymentRecord(orderId);
  }

  Future<List<SalesOrderModel>> getTodayOrders(String agentId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _orders
        .where('agentId', isEqualTo: agentId)
        .where('status', isEqualTo: 'issued')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    return snap.docs.map((d) => SalesOrderModel.fromFirestore(d)).toList();
  }
}
