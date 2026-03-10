import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double total;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) => OrderItem(
        productId: data['productId'] ?? '',
        productName: data['productName'] ?? '',
        unit: data['unit'] ?? 'pcs',
        quantity: (data['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
        total: (data['total'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'unit': unit,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };
}

class SalesOrderModel {
  final String id;
  final String agentId;
  final String shopId;
  final String shopName;
  final List<OrderItem> items;
  final double total;
  // status: 'draft' | 'issued'
  final String status;
  final DateTime createdAt;

  SalesOrderModel({
    required this.id,
    required this.agentId,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory SalesOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
        .toList();
    return SalesOrderModel(
      id: doc.id,
      agentId: data['agentId'] ?? '',
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      items: itemsList,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'draft',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'agentId': agentId,
        'shopId': shopId,
        'shopName': shopName,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
