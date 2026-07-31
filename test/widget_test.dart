import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qiuzhi/main.dart';
import 'package:qiuzhi/providers/app_state.dart';

void main() {
  testWidgets('求知应用可正常启动并显示今日名词页', (tester) async {
    // 让 SharedPreferences 在测试环境下可用
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.load();

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
  });
}
