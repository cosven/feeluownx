import 'package:dynamic_color/dynamic_color.dart';
import 'package:feeluownx/pages/playlist_ui.dart';
import 'package:feeluownx/search.dart';
import 'package:feeluownx/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'global.dart';
import 'pages/player_control.dart';

Future<void> main() async {
  await Global.init();
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
    const PlayerControlPage(),
    const PlaylistView(),
    const SettingPanel(),
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
          body: TabBarView(
              controller: tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: children),
          bottomNavigationBar: BottomNavigationBar(items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "Playing"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: "Settings")
          ], currentIndex: currentIndex, onTap: onTabChange),
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
