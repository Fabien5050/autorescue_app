import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autorescue_app/main.dart';
import 'package:autorescue_app/models/user_role.dart';
import 'package:autorescue_app/screens/driver_main_dashboard.dart';
import 'package:autorescue_app/screens/driver_registration_screen.dart';
import 'package:autorescue_app/screens/location_permission_screen.dart';
import 'package:autorescue_app/screens/login_screen.dart';
import 'package:autorescue_app/screens/payment_screen.dart';
import 'package:autorescue_app/screens/pending_verification_screen.dart';
import 'package:autorescue_app/screens/splash_screen.dart';
import 'package:autorescue_app/screens/workshop_registration_screen.dart';
import 'package:autorescue_app/widgets/phone_field.dart';

void main() {
  testWidgets('splash shows branding and advances to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AutoRescueApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('SOUTH-WEST REGION'), findsOneWidget);
    expect(find.text('TRUSTED ASSISTANCE NETWORK'), findsOneWidget);

    // Auto-transition after the 3s hold.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome to AutoRescue'), findsOneWidget);
  });

  testWidgets('tapping the splash skips straight to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AutoRescueApp());

    await tester.tap(find.byType(SplashScreen));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('form rejects empty and malformed credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your email address'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(
      find.text('Password must be at least 6 characters'),
      findsOneWidget,
    );
  });

  testWidgets('valid driver credentials open driver registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'driver@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(DriverRegistrationScreen), findsOneWidget);
    expect(find.text('Driver Registration'), findsOneWidget);
  });

  testWidgets('sign up link opens driver registration directly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.byType(DriverRegistrationScreen), findsOneWidget);
  });

  testWidgets('valid mechanic credentials open workshop registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.text('I am a Mechanic'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'mechanic@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkshopRegistrationScreen), findsOneWidget);
    expect(find.text('Register Workshop'), findsOneWidget);
  });

  testWidgets('driver registration validates required fields and password match', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DriverRegistrationScreen()),
    );

    await tester.ensureVisible(find.text('Complete Driver Registration'));
    await tester.tap(find.text('Complete Driver Registration'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your phone number'), findsOneWidget);

    final Finder fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Jane Doe');
    await tester.enterText(fields.at(1), 'driver@example.com');
    await tester.enterText(fields.at(2), '5551234567');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.enterText(fields.at(4), 'different456');
    await tester.ensureVisible(find.text('Complete Driver Registration'));
    await tester.tap(find.text('Complete Driver Registration'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('driver registration Log In link returns to login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.byType(DriverRegistrationScreen), findsOneWidget);

    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(DriverRegistrationScreen), findsNothing);
  });

  testWidgets(
    'workshop registration has no payment fields and validates required inputs',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: WorkshopRegistrationScreen()),
      );

      expect(find.text('Payment Details'), findsNothing);
      expect(find.textContaining('Mobile Money'), findsNothing);
      expect(find.text('Verification & Next Steps'), findsOneWidget);

      await tester.ensureVisible(
        find.text('Submit Credentials for Review'),
      );
      await tester.tap(find.text('Submit Credentials for Review'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(
        find.text('Please enter your operational phone'),
        findsOneWidget,
      );
      expect(find.text('Select at least one service'), findsOneWidget);
    },
  );

  testWidgets(
    'completed workshop registration submits to pending verification',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: WorkshopRegistrationScreen()),
      );

      final Finder fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jane Doe');
      await tester.enterText(fields.at(1), 'jane@example.com');
      await tester.enterText(fields.at(2), '+237 670 000 000');
      await tester.enterText(fields.at(3), 'secret123');
      await tester.enterText(fields.at(4), 'Buea Auto Care Garage');
      await tester.enterText(fields.at(5), '123456789');
      await tester.enterText(fields.at(6), 'M012345678901Y');
      await tester.enterText(fields.at(7), 'Commercial Avenue');

      await tester.ensureVisible(find.text('Towing'));
      await tester.tap(find.text('Towing'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.text('Submit Credentials for Review'),
      );
      await tester.tap(find.text('Submit Credentials for Review'));
      await tester.pumpAndSettle();

      expect(find.byType(PendingVerificationScreen), findsOneWidget);
      expect(find.text('Application Submitted'), findsOneWidget);
    },
  );

  testWidgets('completed driver registration proceeds to payment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DriverRegistrationScreen()),
    );

    final Finder textFormFields = find.byType(TextFormField);
    await tester.enterText(textFormFields.at(0), 'Jane Doe');
    await tester.enterText(textFormFields.at(1), 'jane@example.com');
    await tester.enterText(textFormFields.at(2), 'secret123');
    await tester.enterText(textFormFields.at(3), 'secret123');
    await tester.enterText(textFormFields.at(4), 'Toyota Corolla 2018');
    await tester.enterText(textFormFields.at(5), 'SW 123 AB');
    await tester.enterText(textFormFields.at(6), 'Silver');
    await tester.enterText(textFormFields.at(7), 'John Doe');
    await tester.enterText(textFormFields.at(8), '671111111');

    await tester.enterText(
      find.descendant(
        of: find.byType(PhoneField),
        matching: find.byType(TextField),
      ),
      '670000000',
    );

    await tester.ensureVisible(find.text('Complete Driver Registration'));
    await tester.tap(find.text('Complete Driver Registration'));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentScreen), findsOneWidget);
    expect(find.textContaining('2,000 FCFA'), findsWidgets);
  });

  testWidgets('payment screen toggles method forms and validates the active one', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaymentScreen(userRole: UserRole.mechanic)),
    );

    expect(find.text('5,000 FCFA'), findsWidgets);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Card Number'), findsNothing);

    await tester.ensureVisible(find.text('Credit or Debit Card'));
    await tester.tap(find.text('Credit or Debit Card'));
    await tester.pumpAndSettle();

    expect(find.text('Card Number'), findsOneWidget);
    expect(find.text('Mobile Number'), findsNothing);

    await tester.ensureVisible(
      find.text('Pay 5,000 FCFA & Activate Account'),
    );
    await tester.tap(find.text('Pay 5,000 FCFA & Activate Account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your card number'), findsOneWidget);
    expect(find.text('Enter the name on the card'), findsOneWidget);
  });

  testWidgets('completed MTN payment for a driver opens location permission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PaymentScreen(userRole: UserRole.driver)),
    );

    await tester.enterText(find.byType(TextFormField), '670000000');
    await tester.ensureVisible(
      find.text('Pay 2,000 FCFA & Activate Account'),
    );
    await tester.tap(find.text('Pay 2,000 FCFA & Activate Account'));
    // LocationPermissionScreen's radar pulse repeats forever, so
    // pumpAndSettle() would hang — advance past the submit delay and the
    // route transition with bounded pumps instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(LocationPermissionScreen), findsOneWidget);
    expect(find.text('Help is just a tap away'), findsOneWidget);
  });

  testWidgets('allowing location opens the driver main dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LocationPermissionScreen()),
    );

    await tester.tap(find.text('Allow Location'));
    // The dashboard's home map has a perpetually pulsing "you are here"
    // pin (IndexedStack keeps it mounted even off-tab), so pumpAndSettle()
    // never settles here either — bounded pumps only from here on.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(DriverMainDashboard), findsOneWidget);
  });

  testWidgets('driver dashboard home map emergency button opens SOS tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DriverMainDashboard()));

    expect(find.text('Search for workshop...'), findsOneWidget);

    await tester.tap(find.text('EMERGENCY HELP'));
    await tester.pump();

    expect(find.text('SHARE MY LOCATION'), findsOneWidget);
  });

  testWidgets('bottom nav switches into the workshops tab and opens a profile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DriverMainDashboard()));

    await tester.tap(find.text('Workshops'));
    await tester.pump();

    expect(find.text('Molyko Quick Fix'), findsOneWidget);

    await tester.ensureVisible(find.text('Details').first);
    await tester.tap(find.text('Details').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Services Provided'), findsOneWidget);
  });

  testWidgets('bottom nav switches into the profile tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DriverMainDashboard()));

    await tester.tap(find.text('Profile'));
    await tester.pump();

    expect(find.text('Driver Account'), findsOneWidget);
  });
}
