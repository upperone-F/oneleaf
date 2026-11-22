import 'package:flutter/material.dart';

import 'screens/journal_screen.dart';
import 'services/buddy.dart';
import 'services/storage.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  final buddy = BuddyService();
  runApp(OneleafApp(storage: storage, buddy: buddy));
}

class OneleafApp extends StatelessWidget {
  final StorageService storage;
  final BuddyService buddy;

  const OneleafApp({super.key, required this.storage, required this.buddy});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oneleaf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: JournalScreen(storage: storage, buddy: buddy),
    );
  }
}
