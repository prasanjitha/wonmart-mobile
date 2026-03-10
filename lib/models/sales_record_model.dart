import 'package:cloud_firestore/cloud_firestore.dart';

class SalesRecordModel {
  final String id;
  final String shopId;
  final String shopName;
  final List<SalesRecordItem> items;
  final double totalAmount;
  final DateTime createdAt;

  SalesRecordModel({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.paymentStatus = 'pending', // pending, partial, completed
    this.paidAmount = 0.0,
  });

  final String paymentStatus;
  final double paidAmount;

  factory SalesRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesRecordModel(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((i) => SalesRecordItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'shopId': shopId,
    'shopName': shopName,
    'items': items.map((i) => i.toMap()).toList(),
    'totalAmount': totalAmount,
    'paymentStatus': paymentStatus,
    'paidAmount': paidAmount,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class SalesRecordItem {
  final String productId;
  final String productName;
  final int quantity;
  final String unit;
  final double price; // Retail Price
  final double totalPrice; // Total Retail Price (Qty * Price)
  final double marginPercentage;
  final double agentPrice; // Price after margin
  final double totalAgentPrice; // Qty * agentPrice
  final double totalProfit;

  SalesRecordItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.totalPrice,
    required this.marginPercentage,
    required this.agentPrice,
    required this.totalAgentPrice,
    required this.totalProfit,
  });

  SalesRecordItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    String? unit,
    double? price,
    double? totalPrice,
    double? marginPercentage,
    double? agentPrice,
    double? totalAgentPrice,
    double? totalProfit,
  }) {
    return SalesRecordItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      totalPrice: totalPrice ?? this.totalPrice,
      marginPercentage: marginPercentage ?? this.marginPercentage,
      agentPrice: agentPrice ?? this.agentPrice,
      totalAgentPrice: totalAgentPrice ?? this.totalAgentPrice,
      totalProfit: totalProfit ?? this.totalProfit,
    );
  }

  factory SalesRecordItem.fromMap(Map<String, dynamic> map) {
    return SalesRecordItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unit: map['unit'] ?? 'pcs',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      marginPercentage: (map['marginPercentage'] as num?)?.toDouble() ?? 0.0,
      agentPrice: (map['agentPrice'] as num?)?.toDouble() ?? 0.0,
      totalAgentPrice: (map['totalAgentPrice'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (map['totalProfit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unit': unit,
    'price': price,
    'totalPrice': totalPrice,
    'marginPercentage': marginPercentage,
    'agentPrice': agentPrice,
    'totalAgentPrice': totalAgentPrice,
    'totalProfit': totalProfit,
  };
}
