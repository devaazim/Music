import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'catalog/audius_catalog.dart';
import 'catalog/catalog_provider.dart';
import 'config.dart';
import 'library/library_store.dart';
import 'player/player_controller.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enables background playback + lock-screen / notification controls.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.tunely.channel.audio',
    androidNotificationChannelName: 'Music playback',
    androidNotificationOngoing: true,
  );

  final library = LibraryStore();
  await library.load();

  runApp(
    MultiProvider(
      providers: [
        // Swap AudiusCatalog for a licensed provider later; the UI won't change.
        Provider<CatalogProvider>(create: (_) => AudiusCatalog()),
        ChangeNotifierProvider<PlayerController>(create: (_) => PlayerController()),
        ChangeNotifierProvider<LibraryStore>.value(value: library),
      ],
      child: const TunelyApp(),
    ),
  );
}

class TunelyApp extends StatelessWidget {
  const TunelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0E0E12),
      ),
      home: const AppShell(),
    );
  }
}
