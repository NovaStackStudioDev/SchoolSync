import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schoolsync/core/data/school_database.dart';
import 'package:schoolsync/core/theme/app_theme.dart';
import 'package:schoolsync/core/widgets/live_data.dart';
import 'package:schoolsync/core/widgets/record_form.dart';
import 'package:schoolsync/features/auth/presentation/login_screen.dart';
import 'package:schoolsync/features/auth/presentation/welcome_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (const bool.fromEnvironment('CAPTURE_PREVIEWS') && Platform.isWindows) {
      final loader = FontLoader('Nirmala UI');
      for (final path in [
        'C:/Windows/Fonts/Nirmala.ttf',
        'C:/Windows/Fonts/NirmalaB.ttf',
      ]) {
        if (await File(path).exists()) {
          loader.addFont(
            Future.value(ByteData.sublistView(await File(path).readAsBytes())),
          );
        }
      }
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  testWidgets('welcome advances to real role selection and sign in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: RepaintBoundary(key: boundary, child: const WelcomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/school_logo.webp'),
        boundary.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => _capture(boundary, 'welcome'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    await tester.runAsync(() => _capture(boundary, 'role-selection'));
    await tester.tap(find.text('Teacher'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'login validates before sending credentials, fits a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: RepaintBoundary(key: boundary, child: const LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() => _capture(boundary, 'sign-in'));
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(find.text('වලංගු ඊමේල් එකක් ඇතුළත් කරන්න'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'database errors show retry and successful retry has an empty state',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveData<List<DbRow>>(
              load: () async {
                if (calls++ == 0) throw StateError('Database unavailable');
                return [];
              },
              builder: (_, data) => const ListViewForTest(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load school data'), findsOneWidget);
      expect(find.textContaining('Database unavailable'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('No records yet.'), findsOneWidget);
    },
  );

  testWidgets('record form prevents duplicate saves and retains failed input', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => editRecord(
                context,
                title: 'Add Class',
                fields: const [FieldSpec('name', 'Class name')],
                save: (values) async {
                  calls++;
                  await pending.future;
                  throw StateError('Write failed');
                },
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Grade 10 A');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Grade 10 A'), findsOneWidget);
    expect(find.textContaining('Write failed'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}

class ListViewForTest extends StatelessWidget {
  const ListViewForTest({super.key});
  @override
  Widget build(BuildContext context) => ListView(children: const [NoRecords()]);
}

Future<void> _capture(GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PREVIEWS')) return;
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final picture = await boundary.toImage(pixelRatio: 2);
  final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
  final file = File('build/previews/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  picture.dispose();
}
