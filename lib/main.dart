import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/today_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 先加载本地持久化设置，再启动界面
  final appState = AppState();
  await appState.load();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const QiuzhiApp(),
    ),
  );
}

class QiuzhiApp extends StatelessWidget {
  const QiuzhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '求知',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B7CFA),
        brightness: Brightness.light,
      ),
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

class _HomeState extends State<_Home> {
  int _index = 0;
  final _pages = const [
    TodayScreen(),
    HistoryScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '今日',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '往期',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: '收藏',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
