import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'features/player/data/playback_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration.music());

  final PlaybackService handler = await AudioService.init<PlaybackService>(
    builder: PlaybackService.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'app.kiki.vst_player.audio',
      androidNotificationChannelName: 'KIKI VST PLAYER',
      androidNotificationOngoing: true,
    ),
  );

  runApp(KikiVstApp(audioHandler: handler));
}
