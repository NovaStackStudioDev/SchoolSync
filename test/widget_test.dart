import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schoolsync/core/constants/app_constants.dart';
import 'package:schoolsync/core/models/teacher.dart';
import 'package:schoolsync/core/theme/app_theme.dart';
import 'package:schoolsync/features/auth/presentation/login_screen.dart';
import 'package:schoolsync/features/auth/presentation/register_screen.dart';
import 'package:schoolsync/features/principal/presentation/principal_dashboard.dart';
import 'package:schoolsync/features/teacher/presentation/teacher_dashboard.dart';

void main() {
  test('school branding constants match the emblem', () {
    expect(AppConstants.appName, 'SchoolSync');
    expect(AppConstants.schoolName, 'Kahatagasdigiliya Central College');
    expect(AppConstants.schoolNameSi, contains('කහටගස්දිගිලිය'));
    expect(AppConstants.attendanceCutoffHour, 7);
  });

  test('teacher initials use first and last name', () {
    const teacher = Teacher(
      id: '1',
      employeeNumber: 'EMP-001',
      fullName: 'N. Perera',
      subjects: ['Mathematics'],
      isActive: true,
    );
    expect(teacher.initials, 'NP');
  });

  testWidgets('login shows school branding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LoginScreen(),
      ),
    );
    expect(find.text('SchoolSync'), findsOneWidget);
    expect(find.text('ඇතුළු වන්න'), findsOneWidget);
    expect(find.textContaining('කහටගස්දිගිලිය'), findsWidgets);
    expect(find.text('නව ගුරුවරයෙක්ද?'), findsOneWidget);
  });

  testWidgets('principal home shows operations modules', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const PrincipalDashboard(),
      ),
    );
    expect(find.text('පාසල් කටයුතු'), findsOneWidget);
    expect(find.text('ගුරුවරු'), findsWidgets);
    expect(find.text('ආදේශන'), findsWidgets);
  });

  testWidgets('teacher home shows check-in module', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const TeacherDashboard(),
      ),
    );
    expect(find.text('පැමිණීම සටහන් කරන්න'), findsOneWidget);
    expect(find.text('ආදේශ පාඩම්'), findsWidgets);
  });

  testWidgets('teacher register screen asks for a subject', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const RegisterScreen(),
      ),
    );
    expect(find.text('ගුරු ගිණුම සාදන්න'), findsOneWidget);
    expect(find.text('ගණිතය'), findsOneWidget);
    expect(find.text('ලියාපදිංචි වන්න'), findsOneWidget);
  });
}
