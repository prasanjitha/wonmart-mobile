import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';

class ShopService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _shops => _db.collection('shops');

  Stream<List<ShopModel>> watchAgentShops(
    String agentId, {
    bool descending = true,
  }) {
    return _db
        .collection('agents')
        .doc(agentId)
        .collection('shops')
        .orderBy('createdAt', descending: descending)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ShopModel.fromFirestore(d)).toList(),
        );
  }

  Future<ShopModel?> getShopById(String shopId) async {
    final doc = await _shops.doc(shopId).get();
    if (!doc.exists) return null;
    return ShopModel.fromFirestore(doc);
  }

  Future<void> addShop(ShopModel shop) async {
    final batch = _db.batch();
    final docRef = _shops.doc();
    final shopId = docRef.id;

    final agentShopRef = _db
        .collection('agents')
        .doc(shop.agentId)
        .collection('shops')
        .doc(shopId);

    final data = shop.toMap();

    batch.set(docRef, data);
    batch.set(agentShopRef, data);

    await batch.commit();
  }

  Future<void> updateShop(
    String shopId,
    String agentId,
    Map<String, dynamic> data,
  ) async {
    final batch = _db.batch();
    batch.update(_shops.doc(shopId), data);
    batch.update(
      _db.collection('agents').doc(agentId).collection('shops').doc(shopId),
      data,
    );
    await batch.commit();
  }

  Future<void> deleteShop(String shopId, String agentId) async {
    final batch = _db.batch();
    batch.delete(_shops.doc(shopId));
    batch.delete(
      _db.collection('agents').doc(agentId).collection('shops').doc(shopId),
    );
    await batch.commit();
  }

  Future<List<ShopModel>> getAgentShops(
    String agentId, {
    bool descending = true,
  }) async {
    final snap = await _db
        .collection('agents')
        .doc(agentId)
        .collection('shops')
        .orderBy('createdAt', descending: descending)
        .get();
    return snap.docs.map((d) => ShopModel.fromFirestore(d)).toList();
  }
}
