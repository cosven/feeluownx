import 'package:feeluownx/client.dart';
import 'package:feeluownx/player.dart';
import 'package:get_it/get_it.dart';

class Global {
  static final getIt = GetIt.instance;

  static Future<void> init() async {
    // dependency injection
    getIt.registerSingleton<Client>(Client());
    getIt.registerSingleton<PubsubClient>(PubsubClient());
    getIt.registerSingleton<AudioPlayerHandler>(AudioPlayerHandler());
  }
}
