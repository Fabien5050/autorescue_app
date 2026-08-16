import '../core/api_client.dart';

class ReviewApi {
  ReviewApi._();

  /// Submits the signed-in driver's review for [workshopId]. The backend
  /// allows exactly one review per driver per workshop and answers a repeat
  /// attempt with a 409 ([ApiException.statusCode]), which callers can
  /// treat as "already reviewed" rather than a real failure.
  static Future<void> create({
    required int workshopId,
    required int rating,
    String? comment,
  }) {
    return ApiClient.post('/api/workshops/$workshopId/reviews', <String, dynamic>{
      'rating': rating,
      'comment': comment,
    });
  }
}
