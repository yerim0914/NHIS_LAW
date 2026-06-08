import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nhis_law/main.dart';

void main() {
  testWidgets('home screen loads study app', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: NhisLawApp()));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    expect(find.text('건강보험법 학습'), findsWidgets);
    expect(find.text('오늘의 학습'), findsOneWidget);
    expect(find.text('광고 영역'), findsOneWidget);
  });
}
