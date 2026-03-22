import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';

class RouteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _routes => _db.collection('routes');

  Stream<List<RouteModel>> watchAgentRoutes(String agentId) {
    return _db
        .collection('agents')
        .doc(agentId)
        .collection('routes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => RouteModel.fromFirestore(d)).toList(),
        );
  }

  Future<void> addRoute(RouteModel route) async {
    final batch = _db.batch();
    final docRef = _routes.doc();
    final routeId = docRef.id;

    final agentRouteRef = _db
        .collection('agents')
        .doc(route.agentId)
        .collection('routes')
        .doc(routeId);

    final data = route.toMap();

    batch.set(docRef, data);
    batch.set(agentRouteRef, data);

    batch.commit().catchError((e) {
      // Ignored for offline sync support
    });
  }

  Future<List<RouteModel>> getAgentRoutes(String agentId) async {
    final snap = await _db
        .collection('agents')
        .doc(agentId)
        .collection('routes')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => RouteModel.fromFirestore(d)).toList();
  }

  Future<void> updateRoute(String routeId, String agentId, String name) async {
    final batch = _db.batch();
    final data = {'name': name};

    batch.update(_routes.doc(routeId), data);
    batch.update(
      _db.collection('agents').doc(agentId).collection('routes').doc(routeId),
      data,
    );

    batch.commit().catchError((e) {
      // Ignored for offline sync support
    });
  }

  Future<void> deleteRoute(String routeId, String agentId) async {
    final batch = _db.batch();

    batch.delete(_routes.doc(routeId));
    batch.delete(
      _db.collection('agents').doc(agentId).collection('routes').doc(routeId),
    );

    batch.commit().catchError((e) {
      // Ignored for offline sync support
    });
  }
}
