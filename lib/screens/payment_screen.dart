import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/user_role.dart';
import '../widgets/floating_label_field.dart';
import '../widgets/primary_button.dart';
import 'location_permission_screen.dart';
import 'workshop_owner/workshop_owner_main.dart';

enum PaymentMethod { mtn, orangeMoney, card }

class _PlanDetails {
  const _PlanDetails({
    required this.bannerText,
    required this.summaryTitle,
    required this.licenseSubtitle,
    required this.amountLabel,
  });

  final String bannerText;
  final String summaryTitle;
  final String licenseSubtitle;
  final String amountLabel;
}

const Map<UserRole, _PlanDetails> _plans = <UserRole, _PlanDetails>{
  UserRole.driver: _PlanDetails(
    bannerText: 'Registration Complete! Pay the platform activation fee to '
        'start requesting emergency assistance.',
    summaryTitle: 'AutoRescue Driver Platform Activation Fee',
    licenseSubtitle: 'One-time Registration Fee',
    amountLabel: '2,000 FCFA',
  ),
  UserRole.mechanic: _PlanDetails(
    bannerText: 'Application Approved! Pay the platform subscription fee to '
        'activate your workshop account and start accepting emergency '
        'requests.',
    summaryTitle: 'AutoRescue Workshop Platform Activation Fee',
    licenseSubtitle: '1-Year License',
    amountLabel: '5,000 FCFA',
  ),
};

/// Final "pay the activation fee" step, reached by a driver right after
/// registering or by a workshop once an admin approves its application.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.userRole});

  final UserRole userRole;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _mtnPhoneController = TextEditingController();
  final TextEditingController _orangePhoneController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.mtn;
  bool _isSubmitting = false;

  _PlanDetails get _plan => _plans[widget.userRole]!;

  @override
  void dispose() {
    _mtnPhoneController.dispose();
    _orangePhoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  void _selectMethod(PaymentMethod method) {
    if (_selectedMethod == method) return;
    setState(() => _selectedMethod = method);
  }

  String? _requiredFor(PaymentMethod method, String? value, String message) {
    if (_selectedMethod != method) return null;
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // TODO: re-enable `_formKey.currentState?.validate()` gating once the
    // real payment gateway exists — skipped for now so every screen stays
    // reachable while there's nothing to submit to.

    setState(() => _isSubmitting = true);

    // TODO: charge the selected method via the real payment gateway and
    // activate the account once it confirms.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (widget.userRole == UserRole.driver) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LocationPermissionScreen()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WorkshopOwnerMain()),
    );
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: _goBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.paymentHeader,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Complete Registration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.paymentHeader,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _StatusBanner(text: _plan.bannerText),
                const SizedBox(height: 16),
                _BillingSummaryCard(plan: _plan),
                const SizedBox(height: 22),
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<PaymentMethod>(
                  groupValue: _selectedMethod,
                  onChanged: (PaymentMethod? method) {
                    if (method != null) _selectMethod(method);
                  },
                  child: Column(
                    children: <Widget>[
                      _PaymentMethodCard(
                        method: PaymentMethod.mtn,
                        badge: const _Badge(
                          color: Color(0xFFFFCC00),
                          child: Text(
                            'MTN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        title: 'MTN Mobile Money',
                        subtitle: 'Instant mobile wallet payment',
                        selected: _selectedMethod == PaymentMethod.mtn,
                        onTap: () => _selectMethod(PaymentMethod.mtn),
                        expanded: FloatingLabelField(
                          label: 'Mobile Number',
                          hint: '6 XX XX XX XX',
                          controller: _mtnPhoneController,
                          prefixText: '+237 ',
                          keyboardType: TextInputType.phone,
                          accentColor: AppColors.safetyOrange,
                          validator: (String? v) => _requiredFor(
                            PaymentMethod.mtn,
                            v,
                            'Enter your MTN Mobile Money number',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PaymentMethodCard(
                        method: PaymentMethod.orangeMoney,
                        badge: const _Badge(
                          color: Color(0xFFFF7900),
                          child: Icon(Icons.circle, color: Colors.white, size: 14),
                        ),
                        title: 'Orange Money',
                        subtitle: 'Instant mobile wallet payment',
                        selected: _selectedMethod == PaymentMethod.orangeMoney,
                        onTap: () => _selectMethod(PaymentMethod.orangeMoney),
                        expanded: FloatingLabelField(
                          label: 'Mobile Number',
                          hint: '6 XX XX XX XX',
                          controller: _orangePhoneController,
                          prefixText: '+237 ',
                          keyboardType: TextInputType.phone,
                          accentColor: AppColors.safetyOrange,
                          validator: (String? v) => _requiredFor(
                            PaymentMethod.orangeMoney,
                            v,
                            'Enter your Orange Money number',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PaymentMethodCard(
                        method: PaymentMethod.card,
                        badge: const _Badge(
                          color: AppColors.navy,
                          child: Icon(Icons.credit_card, color: Colors.white, size: 17),
                        ),
                        title: 'Credit or Debit Card',
                        subtitle: 'Visa, Mastercard',
                        selected: _selectedMethod == PaymentMethod.card,
                        onTap: () => _selectMethod(PaymentMethod.card),
                        expanded: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            FloatingLabelField(
                              label: 'Card Number',
                              hint: '0000 0000 0000 0000',
                              controller: _cardNumberController,
                              keyboardType: TextInputType.number,
                              accentColor: AppColors.safetyOrange,
                              prefixIcon: const Icon(
                                Icons.credit_card,
                                size: 18,
                                color: AppColors.slate,
                              ),
                              validator: (String? v) => _requiredFor(
                                PaymentMethod.card,
                                v,
                                'Enter your card number',
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: FloatingLabelField(
                                    label: 'Expiry Date',
                                    hint: 'MM/YY',
                                    controller: _expiryController,
                                    keyboardType: TextInputType.datetime,
                                    accentColor: AppColors.safetyOrange,
                                    validator: (String? v) => _requiredFor(
                                      PaymentMethod.card,
                                      v,
                                      'Required',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FloatingLabelField(
                                    label: 'CVV',
                                    hint: '123',
                                    controller: _cvvController,
                                    obscureText: true,
                                    keyboardType: TextInputType.number,
                                    accentColor: AppColors.safetyOrange,
                                    validator: (String? v) => _requiredFor(
                                      PaymentMethod.card,
                                      v,
                                      'Required',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            FloatingLabelField(
                              label: 'Cardholder Name',
                              hint: 'Name on card',
                              controller: _cardNameController,
                              textCapitalization: TextCapitalization.words,
                              accentColor: AppColors.safetyOrange,
                              validator: (String? v) => _requiredFor(
                                PaymentMethod.card,
                                v,
                                'Enter the name on the card',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isSubmitting
                      ? 'Processing…'
                      : 'Pay ${_plan.amountLabel} & Activate Account',
                  color: AppColors.safetyOrange,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: AppColors.successText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingSummaryCard extends StatelessWidget {
  const _BillingSummaryCard({required this.plan});

  final _PlanDetails plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            plan.summaryTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.licenseSubtitle,
            style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'TOTAL AMOUNT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.slate,
                ),
              ),
              Text(
                plan.amountLabel,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: child,
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.expanded,
  });

  final PaymentMethod method;
  final Widget badge;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget expanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.safetyOrange : AppColors.border,
          width: selected ? 1.6 : 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withValues(alpha: selected ? 0.08 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: <Widget>[
                  badge,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),
                  Radio<PaymentMethod>(
                    value: method,
                    activeColor: AppColors.safetyOrange,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: selected
                ? Padding(padding: const EdgeInsets.only(top: 12), child: expanded)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
