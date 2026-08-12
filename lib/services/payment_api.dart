import '../core/api_client.dart';
import '../models/payment.dart';

class PaymentApi {
  PaymentApi._();

  static Future<Payment> initiate({
    required String method,
    required String purpose,
    required double amount,
    String? phoneNumber,
  }) async {
    final dynamic json = await ApiClient.post('/api/payments/initiate', <String, dynamic>{
      'method': method,
      'purpose': purpose,
      'amount': amount,
      'phoneNumber': phoneNumber,
    });
    return Payment.fromJson(json as Map<String, dynamic>);
  }

  static Future<List<Payment>> listMine() async {
    final dynamic json = await ApiClient.get('/api/payments/me');
    return (json as List<dynamic>)
        .map((dynamic e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
