import 'package:cloud_firestore/cloud_firestore.dart';

enum PlannedMealStatus { suggested, committed }

class PlannedMeal {
  final String id;
  final String recipeId;
  final DateTime day; // date-only
  final String meal; // for now: "dinner"
  final PlannedMealStatus status;
  final String? reason;
  final DateTime createdAt;

  const PlannedMeal({
    required this.id,
    required this.recipeId,
    required this.day,
    required this.meal,
    required this.status,
    this.reason,
    required this.createdAt,
  });

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static PlannedMeal fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? dt(dynamic v) =>
        v is Timestamp ? v.toDate() : (v is DateTime ? v : null);

    final statusStr = (data['status'] as String?) ?? 'suggested';

    return PlannedMeal(
      id: doc.id,
      recipeId: data['recipeId'] as String? ?? '',
      day: _dateOnly(dt(data['day']) ?? DateTime.now()),
      meal: data['meal'] as String? ?? 'dinner',
      status: statusStr == 'committed'
          ? PlannedMealStatus.committed
          : PlannedMealStatus.suggested,
      reason: data['reason'] as String?,
      createdAt: dt(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    Timestamp ts(DateTime d) => Timestamp.fromDate(d);
    return {
      'recipeId': recipeId,
      'day': ts(_dateOnly(day)),
      'meal': meal,
      'status': status.name, // 'suggested' | 'committed'
      if (reason != null) 'reason': reason,
      'createdAt': ts(createdAt),
    };
  }

  PlannedMeal copyWith({
    DateTime? day,
    PlannedMealStatus? status,
    String? reason,
  }) {
    return PlannedMeal(
      id: id,
      recipeId: recipeId,
      day: day ?? this.day,
      meal: meal,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      createdAt: createdAt,
    );
  }
}
