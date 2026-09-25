import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autorescue_app/models/admin_dashboard_summary.dart';
import 'package:autorescue_app/screens/admin/admin_mechanic_verification_screen.dart';

void main() {
  testWidgets('admin verification screen shows pending workshop review actions', (WidgetTester tester) async {
    final List<AdminWorkshopSummary> pending = <AdminWorkshopSummary>[
      AdminWorkshopSummary(
        id: 101,
        name: 'Buea Auto Care',
        address: 'Molyko, Buea',
        verificationStatus: 'PENDING',
        createdAt: DateTime(2026, 9, 20),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AdminMechanicVerificationScreen(initialApplications: pending),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pending workshop applications'), findsOneWidget);
    expect(find.text('Buea Auto Care'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
  });
}
