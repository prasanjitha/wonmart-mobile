import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemModel {
  final String id;
  final String productName;
  final String unit;
  final int quantity;
  final DateTime lastUpdated;

  InventoryItemModel({
    required this.id,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.lastUpdated,
  });

  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItemModel(
      id: doc.id,
      productName: data['productName'] ?? '',
      unit: data['unit'] ?? 'pcs',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'productName': productName,
        'unit': unit,
        'quantity': quantity,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
}
