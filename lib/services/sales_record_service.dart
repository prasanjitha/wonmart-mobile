import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sales_record_model.dart';
import 'store_service.dart';

class SalesRecordService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _salesRecords(String agentId) =>
      _db.collection('agents').doc(agentId).collection('sales_records');

  Future<void> addSalesRecord(String agentId, SalesRecordModel record) async {
    final batch = _db.batch();

    final docId = _db.collection('dummy').doc().id;

    // 1. Agent's main sales records
    final agentSalesRef = _salesRecords(agentId).doc(docId);
    batch.set(agentSalesRef, record.toMap());

    // 2. Shop's specific sales records
    final shopSalesRef = _db
        .collection('agents')
        .doc(agentId)
        .collection('shops')
        .doc(record.shopId)
        .collection('sales_records')
        .doc(docId);
    batch.set(shopSalesRef, record.toMap());

    batch.commit().catchError((e) {
      // Ignored for offline sync support
    });
  }

  Future<String> issueOrderWithPayment({
    required String agentId,
    required String agentName,
    required SalesRecordModel record,
    required String paymentType,
    required String paymentStatus,
    required double paidAmount,
  }) async {
    // 1. Deduct Stock for ordered items
    final Map<String, int> deductions = {
      for (var item in record.items) item.productId: item.quantity,
    };
    if (deductions.isNotEmpty) {
      await StoreService().deductStock(agentId, deductions);
    }

    // 1b. Add Stock for returned items (only if isAddedToStock is true)
    final Map<String, int> additions = {
      for (var item in record.returnItems.where(
        (i) => i.isAddedToStock == true,
      ))
        item.productId: item.quantity,
    };
    if (additions.isNotEmpty) {
      await StoreService().addStock(agentId, additions);
    }

    // 2. Generate Doc ID for Sales Record
    final docId = _db.collection('dummy').doc().id;
    final updatedRecord = SalesRecordModel(
      id: docId,
      shopId: record.shopId,
      shopName: record.shopName,
      items: record.items,
      returnItems: record.returnItems,
      totalAmount: record.totalAmount,
      totalReturnAmount: record.totalReturnAmount,
      createdAt: record.createdAt,
      paymentStatus: paymentStatus,
      paidAmount: paidAmount,
    );

    final batch = _db.batch();

    // 3. Save Sales Record (Agent side)
    final agentSalesRef = _salesRecords(agentId).doc(docId);
    batch.set(agentSalesRef, updatedRecord.toMap());

    // 4. Save Sales Record (Shop side)
    final shopSalesRef = _db
        .collection('agents')
        .doc(agentId)
        .collection('shops')
        .doc(record.shopId)
        .collection('sales_records')
        .doc(docId);
    batch.set(shopSalesRef, updatedRecord.toMap());

    // 5. Save Payment
    final rootRef = _db.collection('all_sale_payments').doc();
    final paymentId = rootRef.id;

    final List<Map<String, dynamic>> modifiedItems = record.items.map((item) {
      final itemMap = item.toMap();
      if (itemMap.containsKey('agentPrice')) {
        itemMap['shopPrice'] = itemMap['agentPrice'];
        itemMap.remove('agentPrice');
      }
      if (itemMap.containsKey('totalAgentPrice')) {
        itemMap['totalShopPrice'] = itemMap['totalAgentPrice'];
        itemMap.remove('totalAgentPrice');
      }
      return itemMap;
    }).toList();

    final List<Map<String, dynamic>> modifiedReturnItems = record.returnItems
        .map((item) {
          final itemMap = item.toMap();
          if (itemMap.containsKey('agentPrice')) {
            itemMap['shopPrice'] = itemMap['agentPrice'];
            itemMap.remove('agentPrice');
          }
          if (itemMap.containsKey('totalAgentPrice')) {
            itemMap['totalShopPrice'] = itemMap['totalAgentPrice'];
            itemMap.remove('totalAgentPrice');
          }
          return itemMap;
        })
        .toList();

    final paymentData = {
      // Model requirements for backwards compatibility
      'id': paymentId,
      'salesRecordId': docId,
      'payAmount': paidAmount,
      'status': paymentStatus,
      'agentId': agentId,
      'agentName': agentName,
      'paymentType': paymentType,

      // Explicit fields required from screenshot
      'createdAt': FieldValue.serverTimestamp(),
      'items': modifiedItems,
      'returnItems': modifiedReturnItems,
      'paidAmount': paidAmount,
      'paymentStatus': paymentStatus,
      'shopId': record.shopId,
      'shopName': record.shopName,
      'totalAmount': record.totalAmount,
      'totalReturnAmount': record.totalReturnAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Root collection: all_sale_payments
    batch.set(rootRef, paymentData);

    // Agent collection: agents/{agentId}/sales_payment
    final agentPaymentRef = _db
        .collection('agents')
        .doc(agentId)
        .collection('sales_payment')
        .doc(paymentId);
    batch.set(agentPaymentRef, paymentData);

    // Shop collection: agents/{agentId}/shops/{shopId}/sales_payment
    final shopPaymentRef = _db
        .collection('agents')
        .doc(agentId)
        .collection('shops')
        .doc(record.shopId)
        .collection('sales_payment')
        .doc(paymentId);
    batch.set(shopPaymentRef, paymentData);

    // Update daily collection aggregate
    if (paidAmount > 0) {
      final now = DateTime.now();
      final dateString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final dailyRef = _db
          .collection('agents')
          .doc(agentId)
          .collection('daily_collections')
          .doc(dateString);

      batch.set(dailyRef, {
        'date': dateString,
        'collectedAmount': FieldValue.increment(paidAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    batch.commit().catchError((e) {
      // Ignored for offline sync support
    });

    return docId;
  }

  Stream<List<SalesRecordModel>> watchSalesRecords(String agentId) {
    return _salesRecords(agentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SalesRecordModel.fromFirestore(d)).toList(),
        );
  }

  Stream<List<SalesRecordModel>> watchShopSalesRecords(
    String agentId,
    String shopId,
  ) {
    return _db
        .collection('agents')
        .doc(agentId)
        .collection('shops')
        .doc(shopId)
        .collection('sales_records')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SalesRecordModel.fromFirestore(d)).toList(),
        );
  }

  Future<double> getTodayTotalSales(String agentId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _salesRecords(agentId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    double total = 0;
    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['totalAmount'] ?? 0.0).toDouble();
    }
    return total;
  }

  Future<double> getOutstandingBalance(String agentId) async {
    final snap = await _salesRecords(agentId).get();
    double totalOutstanding = 0;
    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final totalAmount = (data['totalAmount'] ?? 0.0).toDouble();
      final totalReturnAmount = (data['totalReturnAmount'] ?? 0.0).toDouble();
      final paidAmount = (data['paidAmount'] ?? 0.0).toDouble();
      totalOutstanding += (totalAmount - totalReturnAmount - paidAmount);
    }
    return totalOutstanding;
  }

  Future<double> getMonthlySales(String agentId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final snap = await _salesRecords(agentId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    double total = 0;
    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['totalAmount'] ?? 0.0).toDouble();
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getTopSoldProducts(String agentId) async {
    final snap = await _salesRecords(agentId).get();
    final Map<String, Map<String, dynamic>> productTotals = {};

    for (var doc in snap.docs) {
      final record = SalesRecordModel.fromFirestore(doc);
      for (var item in record.items) {
        if (productTotals.containsKey(item.productId)) {
          productTotals[item.productId]!['totalQuantity'] += item.quantity;
        } else {
          productTotals[item.productId] = {
            'productName': item.productName,
            'totalQuantity': item.quantity,
            'unit': item.unit,
          };
        }
      }
    }

    final sortedList = productTotals.values.toList()
      ..sort((a, b) => b['totalQuantity'].compareTo(a['totalQuantity']));

    return sortedList.take(5).toList();
  }

  Stream<double> watchTodayTotalSales(String agentId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _salesRecords(agentId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snap) {
          double total = 0;
          for (var doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            total += (data['totalAmount'] ?? 0.0).toDouble();
          }
          return total;
        });
  }

  Stream<double> watchOutstandingBalance(String agentId) {
    return _salesRecords(agentId).snapshots().map((snap) {
      double totalOutstanding = 0;
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final totalAmount = (data['totalAmount'] ?? 0.0).toDouble();
        final totalReturnAmount = (data['totalReturnAmount'] ?? 0.0).toDouble();
        final paidAmount = (data['paidAmount'] ?? 0.0).toDouble();
        totalOutstanding += (totalAmount - totalReturnAmount - paidAmount);
      }
      return totalOutstanding;
    });
  }

  Stream<double> watchMonthlySales(String agentId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return _salesRecords(agentId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snap) {
          double total = 0;
          for (var doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            total += (data['totalAmount'] ?? 0.0).toDouble();
          }
          return total;
        });
  }

  Future<List<SalesRecordModel>> getSalesRecordsInRange(
    String agentId,
    DateTime start,
    DateTime end,
  ) async {
    // Ensure end of day for the end date
    final endOfPeriod = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final snap = await _salesRecords(agentId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfPeriod),
        )
        .get();
    return snap.docs.map((d) => SalesRecordModel.fromFirestore(d)).toList();
  }

  Future<void> deleteSalesRecord(
    String agentId,
    SalesRecordModel record,
  ) async {
    // 1. Add back stock for the sold items
    final Map<String, int> additions = {
      for (var item in record.items) item.productId: item.quantity,
    };
    if (additions.isNotEmpty) {
      await StoreService().addStock(agentId, additions);
    }

    // 2. We could deduct the returned items if needed, but the instruction specifically implies adding back the sold items.
    final Map<String, int> deductions = {
      for (var item in record.returnItems.where(
        (i) => i.isAddedToStock == true,
      ))
        item.productId: item.quantity,
    };
    if (deductions.isNotEmpty) {
      await StoreService().deductStock(agentId, deductions);
    }

    final batch = _db.batch();

    // 3. Delete from Agent Sales Records
    batch.delete(_salesRecords(agentId).doc(record.id));

    // 4. Delete from Shop Sales Records
    batch.delete(
      _db
          .collection('agents')
          .doc(agentId)
          .collection('shops')
          .doc(record.shopId)
          .collection('sales_records')
          .doc(record.id),
    );

    // 5. Query related payments
    final existingPayments = await _db
        .collection('all_sale_payments')
        .where('salesRecordId', isEqualTo: record.id)
        .get();

    for (var doc in existingPayments.docs) {
      final paymentId = doc.id;
      final data = doc.data() as Map<String, dynamic>?;

      if (data != null) {
        final double amountToSubtract = (data['paidAmount'] ?? data['payAmount'] ?? 0.0).toDouble();

        if (amountToSubtract > 0) {
          final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
          final DateTime paymentDate = createdAtTimestamp?.toDate() ?? record.createdAt;
          final dateString = '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')}';

          final dailyRef = _db
              .collection('agents')
              .doc(agentId)
              .collection('daily_collections')
              .doc(dateString);

          batch.set(dailyRef, {
            'date': dateString,
            'collectedAmount': FieldValue.increment(-amountToSubtract),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // Delete from all_sale_payments
      batch.delete(doc.reference);
      // Delete from agent sales_payment
      batch.delete(
        _db
            .collection('agents')
            .doc(agentId)
            .collection('sales_payment')
            .doc(paymentId),
      );
      // Delete from shop sales_payment
      batch.delete(
        _db
            .collection('agents')
            .doc(agentId)
            .collection('shops')
            .doc(record.shopId)
            .collection('sales_payment')
            .doc(paymentId),
      );
    }

    batch.commit().catchError((e) {
      // Ignored for offline sync support
    });
  }
}
