import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:feeluownx/pages/configuration.dart';
import 'package:feeluownx/pages/playlist_ui.dart';
import 'package:feeluownx/search.dart';
import 'package:feeluownx/widgets/small_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
// import 'package:serious_python/serious_python.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:logging/logging.dart';

import 'global.dart';
import 'pages/player_control.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  Logger.root.level = Level.ALL;
  MediaKit.ensureInitialized();
  await Global.init();
  await Settings.init(cacheProvider: SharePreferenceCache());
  // final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  // SeriousPython.run(
  //   "app/app.zip",
  //   environmentVariables: {"FEELUOWN_USER_HOME": appDocumentsDir.path}
  // );
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  final List<Widget> children = [
    const HomePage(),
    const PlayerControlPage(),
    const PlaylistView(),
    const ConfigurationPage(),
  ];

  late TabController tabController;

  // default theme when dynamic color cannot be found
  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.blue);
  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: children.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('FeelUOwn'),
          ),
          body: Stack(children: [
            TabBarView(
                controller: tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: children),
            const Positioned(
                bottom: 0, left: 0, right: 0, child: SmallPlayerWidget())
          ]),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: "Player"),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: "Playing"),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings")
            ],
            currentIndex: currentIndex,
            onTap: onTabChange,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          floatingActionButton: Builder(
              builder: (context) => FloatingActionButton(
                  onPressed: () async {
                    await showSearch(
                        context: context,
                        delegate: Global.getIt<SongSearchDelegate>());
                  },
                  child: const Icon(Icons.search))),
        ),
        // auto dark mode follows system settings
        themeMode: ThemeMode.system,
        theme: ThemeData(
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          useMaterial3: true,
        ),
      );
    });
  }

  void onTabChange(int index) {
    setState(() {
      tabController.index = currentIndex = index;
    });
  }
}
