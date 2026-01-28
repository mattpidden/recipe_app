import 'package:cloud_firestore/cloud_firestore.dart';

class CookEvent {
  final String id;

  final String recipeId;
  final String? cookbookId;

  final DateTime cookedAt;

  final int rating; // 1..5
  final String? comment;

  final String? occasion; // e.g. "Birthday", "Sunday roast"
  final List<String> withWho; // e.g. ["Matt", "Jess"]

  final bool? wouldMakeAgain;

  const CookEvent({
    required this.id,
    required this.recipeId,
    this.cookbookId,
    required this.cookedAt,
    required this.rating,
    this.comment,
    this.occasion,
    this.withWho = const [],
    this.wouldMakeAgain,
  });

  static CookEvent fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime dt(dynamic v) =>
        v is Timestamp ? v.toDate() : (v is DateTime ? v : DateTime.now());

    List<String> strList(dynamic v) {
      if (v is! List) return const [];
      return v.whereType<String>().toList();
    }

    return CookEvent(
      id: doc.id,
      recipeId: data['recipeId'] as String? ?? '',
      cookbookId: data['cookbookId'] as String?,
      cookedAt: dt(data['cookedAt']),
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      comment: data['comment'] as String?,
      occasion: data['occasion'] as String?,
      withWho: strList(data['withWho']),
      wouldMakeAgain: data['wouldMakeAgain'] as bool?,
    );
  }

  Map<String, dynamic> toFirestore() {
    Timestamp ts(DateTime d) => Timestamp.fromDate(d);

    return {
      'recipeId': recipeId,
      if (cookbookId != null) 'cookbookId': cookbookId,
      'cookedAt': ts(cookedAt),
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (occasion != null) 'occasion': occasion,
      'withWho': withWho,
      if (wouldMakeAgain != null) 'wouldMakeAgain': wouldMakeAgain,
    };
  }
}
