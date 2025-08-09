import 'package:firebase_database/firebase_database.dart';

class DBService {
  DBService._();
  static final instance = DBService._();

  final _db = FirebaseDatabase.instance.ref();

  /// Streams Tank1/Tank2 `percentage` as 0..100
  Stream<double> tankPercent(String tankKey) {
    final ref = _db.child('$tankKey/percentage'); // e.g. Tank1/percentage
    return ref.onValue.map((event) {
      final v = event.snapshot.value;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null) return parsed.clamp(0, 100);
      }
      return 0.0;
    });
  }
}
