import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _products(String agentId) =>
      _db.collection('inventory').doc(agentId).collection('products');

  Stream<List<InventoryItemModel>> watchInventory(String agentId) {
    return _products(agentId)
        .orderBy('productName')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => InventoryItemModel.fromFirestore(d)).toList());
  }

  Future<List<InventoryItemModel>> getInventory(String agentId) async {
    final snap = await _products(agentId).orderBy('productName').get();
    return snap.docs.map((d) => InventoryItemModel.fromFirestore(d)).toList();
  }

  Future<void> addOrUpdateProduct(
      String agentId, InventoryItemModel item) async {
    await _products(agentId).doc(item.id.isEmpty ? null : item.id).set(
          item.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Deduct quantities from inventory after a sales order is issued.
  /// [deductions] is a map of {productId: quantityToDeduct}
  Future<void> deductStock(
      String agentId, Map<String, int> deductions) async {
    final batch = _db.batch();
    deductions.forEach((productId, qty) {
      final ref = _products(agentId).doc(productId);
      batch.update(ref, {'quantity': FieldValue.increment(-qty)});
    });
    await batch.commit();
  }
}
