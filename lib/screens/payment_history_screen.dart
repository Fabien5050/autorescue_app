import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../models/payment.dart';
import '../services/payment_api.dart';

/// Driver's own payment history — real records from `GET /api/payments/me`.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late Future<List<Payment>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = PaymentApi.listMine();
  }

  Future<void> _refresh() async {
    setState(() {
      _paymentsFuture = PaymentApi.listMine();
    });
    await _paymentsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.heading,
        title: const Text('Payment History', style: TextStyle(color: AppColors.heading, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Payment>>(
          future: _paymentsFuture,
          builder: (BuildContext context, AsyncSnapshot<List<Payment>> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final String message = snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Failed to load payment history.';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _refresh, child: const Text('Retry')),
                    ],
                  ),
                ),
              );
            }

            final List<Payment> payments = snapshot.data ?? const <Payment>[];
            if (payments.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 72,
                            height: 72,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.badgeSoft, shape: BoxShape.circle),
                            child: const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.primaryBlue),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No payments yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.heading),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: payments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) => _PaymentCard(payment: payments[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final Payment payment;

  Color get _statusColor => switch (payment.status) {
    'SUCCESS' => AppColors.accentGreen,
    'PENDING' => AppColors.warningOrange,
    'FAILED' => AppColors.dangerRed,
    _ => AppColors.secondaryText,
  };

  String get _methodLabel => switch (payment.method) {
    'MTN_MOMO' => 'MTN Mobile Money',
    'ORANGE_MONEY' => 'Orange Money',
    'CARD' => 'Card',
    _ => payment.method,
  };

  String get _purposeLabel => switch (payment.purpose) {
    'DRIVER_ACTIVATION' => 'Driver Activation Fee',
    'WORKSHOP_ACTIVATION' => 'Workshop Activation Fee',
    _ => payment.purpose,
  };

  String get _dateLabel {
    final DateTime d = payment.createdAt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  _purposeLabel,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  payment.status,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: _statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryText),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              const Icon(Icons.payments_outlined, size: 13, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text(_methodLabel, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              const SizedBox(width: 12),
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text(_dateLabel, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
            ],
          ),
        ],
      ),
    );
  }
}
