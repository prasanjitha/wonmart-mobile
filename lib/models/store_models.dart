import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StoreItemModel {
  final String id;
  final String productName;
  final String unit;
  final int quantity;
  final double price;
  final DateTime lastUpdated;

  StoreItemModel({
    required this.id,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.lastUpdated,
  });

  factory StoreItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime lastUpdatedDate = DateTime.now();
    final lu = data['lastUpdated'];
    if (lu is Timestamp) {
      lastUpdatedDate = lu.toDate();
    } else if (lu is String) {
      lastUpdatedDate = DateTime.tryParse(lu) ?? DateTime.now();
    }

    return StoreItemModel(
      id: doc.id,
      productName: data['productName'] ?? '',
      unit: data['unit'] ?? 'pcs',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: lastUpdatedDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'productName': productName,
    'unit': unit,
    'quantity': quantity,
    'price': price,
    'lastUpdated': FieldValue.serverTimestamp(),
  };
}

class StoreHistoryModel {
  final String id;
  final DateTime date;
  final String time;
  final List<StoreHistoryProduct> products;

  StoreHistoryModel({
    required this.id,
    required this.date,
    required this.time,
    required this.products,
  });

  factory StoreHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((p) => StoreHistoryProduct.fromMap(p as Map<String, dynamic>))
        .toList();

    DateTime dateVal = DateTime.now();
    String timeVal = '';
    final ts = data['timestamp'];
    if (ts is Timestamp) {
      dateVal = ts.toDate();
      timeVal = DateFormat('HH:mm').format(dateVal);
    } else if (ts is String) {
      final parsed = DateTime.tryParse(ts);
      if (parsed != null) {
        dateVal = parsed;
        timeVal = DateFormat('HH:mm').format(parsed);
      }
    }

    return StoreHistoryModel(
      id: doc.id,
      date: dateVal,
      time: timeVal,
      products: itemsList,
    );
  }
}

class StoreHistoryProduct {
  final String productName;
  final String unit;
  final int quantity;

  StoreHistoryProduct({
    required this.productName,
    required this.unit,
    required this.quantity,
  });

  factory StoreHistoryProduct.fromMap(Map<String, dynamic> map) {
    return StoreHistoryProduct(
      productName: map['productName'] ?? '',
      unit: map['unit'] ?? 'pcs',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}
