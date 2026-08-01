import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qiuzhi/main.dart';
import 'package:qiuzhi/models/word.dart';
import 'package:qiuzhi/providers/app_state.dart';
import 'package:qiuzhi/screens/word_detail_screen.dart';

void main() {
  testWidgets('求知应用可正常启动并显示今日名词页', (tester) async {
    // 让 SharedPreferences 在测试环境下可用
    SharedPreferences.setMockInitialValues({'remoteUrl': ''});
    final appState = AppState();
    await tester.runAsync(appState.load);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const QiuzhiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 底部导航与标题存在
    expect(find.text('今日'), findsWidgets);
    expect(find.text('求知'), findsWidgets);
    expect(find.text('LV.1'), findsOneWidget);
    expect(find.text('求知新芽'), findsOneWidget);
    expect(find.text('???'), findsOneWidget);
    expect(find.text('点击抽取第 1 个词'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.list_alt_outlined));
    await tester.pumpAndSettle();
    expect(find.text('待抽取词语'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('点击抽取第 1 个词'));
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await tester.pumpAndSettle();
    expect(find.text('???'), findsNothing);
    expect(find.text('开始第 1 个词'), findsOneWidget);

    await tester.tap(find.text('抽词范围 · 点击调整'));
    await tester.pumpAndSettle();
    expect(find.text('参与抽取的词包'), findsOneWidget);
    final rangeSheet = find.ancestor(
      of: find.text('参与抽取的词包'),
      matching: find.byType(Scrollable),
    );
    await tester.drag(rangeSheet, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成设置'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.list_alt_outlined));
    await tester.pumpAndSettle();
    expect(find.text('今日词单'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('热词'));
    await tester.pumpAndSettle();
    expect(find.text('热词库'), findsOneWidget);
    expect(find.text('按时间'), findsOneWidget);
    expect(find.text('按类型'), findsOneWidget);
  });

  testWidgets('词语详细页保留标准解释并展示四个详解模块', (tester) async {
    const word = Word(
      id: 1,
      word: '算力',
      pinyin: 'suàn lì',
      field: '通用',
      difficulty: '中',
      pack: '每日热词',
      definition: '这是列表中保持不变的标准解释。',
      simpleExplanation: '电脑一秒能算多少道题。',
      lifeAnalogy: '像餐厅同时能用多少个灶台。',
      practicalApplication: '用于运行人工智能服务。',
      commonMisconception: '不只是购买显卡。',
    );

    await tester.pumpWidget(
      const MaterialApp(home: WordDetailScreen(word: word)),
    );

    expect(find.text('标准解释'), findsOneWidget);
    expect(find.text('这是列表中保持不变的标准解释。'), findsOneWidget);
    expect(find.text('一句话解释'), findsOneWidget);
    expect(find.text('生活类比'), findsOneWidget);
    expect(find.text('实际应用'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('常见误区'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('常见误区'), findsOneWidget);
  });
}
