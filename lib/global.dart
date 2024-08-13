import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:feeluownx/client.dart';
import 'package:feeluownx/player.dart';
import 'package:feeluownx/search.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class Global {
  static final getIt = GetIt.instance;

  static Future<void> init() async {
    // dependency injection
    WidgetsFlutterBinding.ensureInitialized();
    getIt.registerSingleton<Client>(Client());
    getIt.registerSingleton<PubsubClient>(PubsubClient());
    getIt.registerSingleton<AudioPlayerHandler>(AudioPlayerHandler());
    getIt.registerSingleton<AudioHandler>(await initAudioHandler());
    getIt.registerSingleton<SongSearchDelegate>(SongSearchDelegate());
    HttpOverrides.global = _HttpOverrides();
  }

  static Future<AudioHandler> initAudioHandler() async {
    AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();
    // 好像还是不行，这个地方有点问题
    return await AudioService.init(
      builder: () => handler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'io.github.feeluown',
        androidNotificationChannelName: 'FeelUOwn',
        androidNotificationOngoing: true,
      ),
    );
  }
}

class _HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent =
          'Mozilla/5.0 (X11; Linux x86_64; rv:129.0) Gecko/20100101 Firefox/129.0';
  }
}
