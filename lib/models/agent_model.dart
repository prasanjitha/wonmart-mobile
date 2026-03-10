import 'package:cloud_firestore/cloud_firestore.dart';

class AgentModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String region;
  final DateTime createdAt;

  AgentModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.region,
    required this.createdAt,
  });

  factory AgentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgentModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      region: data['region'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'region': region,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
