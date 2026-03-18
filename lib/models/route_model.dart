import 'package:cloud_firestore/cloud_firestore.dart';

class RouteModel {
  final String id;
  final String agentId;
  final String name;
  final DateTime createdAt;

  RouteModel({
    required this.id,
    required this.agentId,
    required this.name,
    required this.createdAt,
  });

  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RouteModel(
      id: doc.id,
      agentId: data['agentId'] ?? '',
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'agentId': agentId,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
