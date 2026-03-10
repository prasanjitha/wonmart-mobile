import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_models.dart';

class StoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _agentStore(String agentId) =>
      _db.collection('agents').doc(agentId).collection('agent_store');

  CollectionReference _storeHistory(String agentId) => _db
      .collection('agents')
      .doc(agentId)
      .collection('pertime_warehouse_itemlists');

  Stream<List<StoreItemModel>> watchAgentStore(String agentId) {
    return _agentStore(agentId)
        .orderBy('productName')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => StoreItemModel.fromFirestore(d)).toList(),
        );
  }

  Future<List<StoreItemModel>> getAgentStore(String agentId) async {
    final snap = await _agentStore(agentId).orderBy('productName').get();
    return snap.docs.map((d) => StoreItemModel.fromFirestore(d)).toList();
  }

  Future<void> deductStock(String agentId, Map<String, int> deductions) async {
    final batch = _db.batch();
    final storeRef = _agentStore(agentId);

    for (var entry in deductions.entries) {
      final docRef = storeRef.doc(entry.key);
      batch.update(docRef, {
        'quantity': FieldValue.increment(-entry.value),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Stream<List<StoreHistoryModel>> watchStoreHistory(String agentId) {
    return _storeHistory(agentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => StoreHistoryModel.fromFirestore(d)).toList(),
        );
  }
}
