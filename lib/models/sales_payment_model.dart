import 'package:cloud_firestore/cloud_firestore.dart';

class SalesPaymentModel {
  final String id;
  final String salesRecordId;
  final double totalAmount;
  final double payAmount;
  final String status; // partial, completed
  final DateTime createdAt;
  final String agentId;
  final String agentName;
  final String shopId;
  final String shopName;
  final String paymentType; // full, partial

  SalesPaymentModel({
    required this.id,
    required this.salesRecordId,
    required this.totalAmount,
    required this.payAmount,
    required this.status,
    required this.createdAt,
    required this.agentId,
    required this.agentName,
    required this.shopId,
    required this.shopName,
    required this.paymentType,
  });

  factory SalesPaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesPaymentModel(
      id: doc.id,
      salesRecordId: data['salesRecordId'] ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      payAmount: (data['payAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      agentId: data['agentId'] ?? '',
      agentName: data['agentName'] ?? '',
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      paymentType: data['paymentType'] ?? 'full',
    );
  }

  Map<String, dynamic> toMap() => {
    'salesRecordId': salesRecordId,
    'totalAmount': totalAmount,
    'payAmount': payAmount,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
    'agentId': agentId,
    'agentName': agentName,
    'shopId': shopId,
    'shopName': shopName,
    'paymentType': paymentType,
  };

  SalesPaymentModel copyWith({
    String? id,
    String? salesRecordId,
    double? totalAmount,
    double? payAmount,
    String? status,
    DateTime? createdAt,
    String? agentId,
    String? agentName,
    String? shopId,
    String? shopName,
    String? paymentType,
  }) {
    return SalesPaymentModel(
      id: id ?? this.id,
      salesRecordId: salesRecordId ?? this.salesRecordId,
      totalAmount: totalAmount ?? this.totalAmount,
      payAmount: payAmount ?? this.payAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      paymentType: paymentType ?? this.paymentType,
    );
  }
}
