import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qiuzhi/providers/app_state.dart';
import 'package:qiuzhi/screens/vocabulary_search_screen.dart';
import 'package:qiuzhi/theme/pixel_theme.dart';

void main() {
  testWidgets('搜索栏可搜索词汇和词汇包', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          theme: buildPixelTheme(),
          home: const VocabularySearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('搜索词汇与词包'), findsOneWidget);
    expect(find.text('通用知识包'), findsOneWidget);

    final field = find.byKey(const Key('vocabulary-search-field'));
    await tester.enterText(field, '熵');
    await tester.pump();
    expect(find.text('熵'), findsWidgets);
    expect(find.text('1 个词汇'), findsOneWidget);

    await tester.enterText(field, '通用知识包');
    await tester.pump();
    expect(find.text('通用知识包'), findsWidgets);
    expect(find.text('1 个词包'), findsOneWidget);
  });
}
