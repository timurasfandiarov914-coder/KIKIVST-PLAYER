import 'package:flutter/material.dart';

import 'features/catalog/domain/catalog_search_service.dart';
import 'features/player/data/playback_service.dart';
import 'features/player/presentation/home_screen.dart';
import 'features/resolver/domain/stream_resolver.dart';

class KikiVstApp extends StatelessWidget {
  const KikiVstApp({required this.audioHandler, super.key});

  final PlaybackService audioHandler;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC8FF45);

    return MaterialApp(
      title: 'KIKI VST PLAYER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF090B0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: const Color(0xFF121512),
        ),
        dividerColor: Colors.white12,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF090B0A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: HomeScreen(
        audioHandler: audioHandler,
        searchService: CatalogSearchService(sources: const []),
        resolver: CompositeStreamResolver(resolvers: const []),
      ),
    );
  }
}
