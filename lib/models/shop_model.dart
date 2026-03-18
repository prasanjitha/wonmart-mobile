import 'package:cloud_firestore/cloud_firestore.dart';

class ShopModel {
  final String id;
  final String agentId;
  final String uniqueId;
  final String name;
  final String address;
  final String phone;
  final String whatsapp;
  final String email;
  final String? routeId;
  final bool hasGps;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  ShopModel({
    required this.id,
    required this.agentId,
    required this.uniqueId,
    required this.name,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.email,
    this.routeId,
    this.hasGps = false,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory ShopModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopModel(
      id: doc.id,
      agentId: data['agentId'] ?? '',
      uniqueId: data['uniqueId'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      whatsapp: data['whatsapp'] ?? '',
      email: data['email'] ?? '',
      routeId: data['routeId'],
      hasGps: data['hasGps'] ?? false,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'agentId': agentId,
        'uniqueId': uniqueId,
        'name': name,
        'address': address,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'routeId': routeId,
        'hasGps': hasGps,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
      };

  ShopModel copyWith({
    String? name,
    String? address,
    String? phone,
    String? whatsapp,
    String? email,
    String? routeId,
    bool? hasGps,
    double? latitude,
    double? longitude,
  }) =>
      ShopModel(
        id: id,
        agentId: agentId,
        uniqueId: uniqueId,
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        email: email ?? this.email,
        routeId: routeId ?? this.routeId,
        hasGps: hasGps ?? this.hasGps,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        createdAt: createdAt,
      );
}
