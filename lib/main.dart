import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/today_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/hotword_library_screen.dart';
import 'theme/pixel_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 先绘制第一帧，再异步恢复本地数据。存储插件或旧数据异常时，
  // 应用仍能使用默认设置启动，避免永远停留在原生启动页。
  final appState = AppState();
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const QiuzhiApp(),
    ),
  );
  unawaited(appState.load());
}

class QiuzhiApp extends StatelessWidget {
  const QiuzhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final visualTheme = context.watch<AppState>().visualTheme;
    return MaterialApp(
      title: '求知',
      debugShowCheckedModeBanner: false,
      theme: buildPixelTheme(visualTheme: visualTheme),
      // 路由：ResultScreen 完成后用 '/today' 回首页
      initialRoute: '/today',
      routes: {
        '/today': (ctx) => const _Home(),
      },
    );
  }
}

/// 主页：底部导航 今日 / 往期 / 收藏 / 我的
class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> with WidgetsBindingObserver {
  int _index = 0;
  final _pages = const [
    TodayScreen(),
    HotwordLibraryScreen(),
    HistoryScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<AppState>().refreshRemoteIfDue());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: _PixelNavigation(
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _PixelNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PixelNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = [
    (Icons.today_outlined, '今日'),
    (Icons.local_fire_department_outlined, '热词'),
    (Icons.history_outlined, '往期'),
    (Icons.star_outline, '收藏'),
    (Icons.tune, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: palette.white,
          border: Border(top: BorderSide(color: palette.ink, width: 2)),
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final selected = selectedIndex == index;
            final item = _items[index];
            return Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? palette.accent : Colors.transparent,
                    border: selected
                        ? Border.all(color: palette.ink, width: 1.5)
                        : null,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$1, size: 20, color: palette.ink),
                      const SizedBox(height: 2),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
