/// A single payment record, mirroring the backend's `PaymentResponse`.
class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.purpose,
    this.providerReference,
    required this.createdAt,
  });

  final int id;
  final double amount;
  final String currency;
  final String method;
  final String status;
  final String purpose;
  final String? providerReference;
  final DateTime createdAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as int,
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] as String,
    method: json['method'] as String,
    status: json['status'] as String,
    purpose: json['purpose'] as String,
    providerReference: json['providerReference'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
