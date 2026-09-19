import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/hydration_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final hydration = HydrationProvider();
  await hydration.load();
  // Notification taps / action buttons work even when the app was closed.
  NotificationService.onAction = (action) async {
    if (action == 'drank_250') {
      await hydration.addWater(250);
    } else if (action == 'snooze_15') {
      await hydration.snooze(const Duration(minutes: 15));
    } else {
      await hydration.ensureScheduled();
    }
  };
  await hydration.ensureScheduled();
  runApp(
    ChangeNotifierProvider.value(
      value: hydration,
      child: const HydroBuddyApp(),
    ),
  );
}

class HydroBuddyApp extends StatelessWidget {
  const HydroBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroBuddy — Hydration Reminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _Tabs(),
    );
  }
}

class _Tabs extends StatefulWidget {
  const _Tabs();
  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onViewAllHistory: () => setState(() => _i = 1)),
      const StatsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.water_drop), label: 'Drink'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
