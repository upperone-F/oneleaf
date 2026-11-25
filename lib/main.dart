import 'package:flutter/material.dart';

import 'screens/bond_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/create_buddy_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/market_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/share_screen.dart';
import 'screens/voice_screen.dart';
import 'screens/weather_screen.dart';
import 'services/buddy.dart';
import 'services/storage.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  final buddy = BuddyService();
  final state = AppState(storage);
  runApp(OneleafApp(storage: storage, buddy: buddy, state: state));
}

class OneleafApp extends StatelessWidget {
  final StorageService storage;
  final BuddyService buddy;
  final AppState state;

  const OneleafApp({
    super.key,
    required this.storage,
    required this.buddy,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oneleaf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: MainShell(storage: storage, buddy: buddy, state: state),
    );
  }
}

/// 主壳：底部导航 5 个入口 + 二级页面通过路由 push。
class MainShell extends StatefulWidget {
  final StorageService storage;
  final BuddyService buddy;
  final AppState state;

  const MainShell({
    super.key,
    required this.storage,
    required this.buddy,
    required this.state,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      JournalScreen(storage: widget.storage, buddy: widget.buddy, state: widget.state),
      CalendarScreen(storage: widget.storage, state: widget.state),
      ChatScreen(buddy: widget.buddy, state: widget.state),
      MarketScreen(state: widget.state),
      SettingsScreen(state: widget.state),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.mintDark,
        unselectedItemColor: AppTheme.inkSoft,
        backgroundColor: AppTheme.card,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: '日记'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: '日历'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '对话'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Buddy'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: '我的'),
        ],
      ),
    );
  }
}

/// 全局二级页面路由表，供各页面统一调用，避免散落的 Navigator 代码。
class Routes {
  static void weather(BuildContext context, StorageService storage) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => WeatherScreen(storage: storage)));

  static void voice(BuildContext context, StorageService storage, BuddyService buddy) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => VoiceScreen(storage: storage, buddy: buddy)));

  static void share(BuildContext context, StorageService storage) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShareScreen(storage: storage)));

  static void insights(BuildContext context, StorageService storage) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => InsightsScreen(storage: storage)));

  static void bond(BuildContext context, AppState state) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BondScreen(state: state)));

  static void createBuddy(BuildContext context, AppState state) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateBuddyScreen(state: state)));
}
