import 'dart:io';

import 'package:feeluownx/client.dart';
import 'package:feeluownx/player.dart';
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

    HttpOverrides.global = _HttpOverrides();
  }
}

class _HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'Mozilla/5.0 (X11; Linux x86_64; rv:129.0) Gecko/20100101 Firefox/129.0';
  }
}
