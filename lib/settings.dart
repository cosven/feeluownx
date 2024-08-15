import 'package:feeluownx/global.dart';
import 'package:feeluownx/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:optimize_battery/optimize_battery.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPanel extends StatefulWidget {
  const SettingPanel({super.key});

  @override
  State<StatefulWidget> createState() => SettingState();
}

class SettingState extends State<SettingPanel> {
  static const String settingsKeyDaemonIp = "settings_ip_address";

  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();

  @override
  Widget build(BuildContext context) {
    return SettingsList(sections: [
      SettingsSection(tiles: [
        SettingsTile(
          title: const Text("Instance IP"),
          description: const Text("The IP Address of FeelUOwn daemon"),
          leading: const Icon(Icons.rss_feed),
          value: FutureBuilder(
              future: prefs.getString(settingsKeyDaemonIp),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                return Text(snapshot.hasData ? snapshot.data! : "");
              }),
          onPressed: (BuildContext context) async {
            String? value = await showInputDialog(context,
                const Text("Instance IP"), "The IP Address of FeelUOwn daemon");
            if (value != null) {
              setState(() {
                prefs.setString(settingsKeyDaemonIp, value);
              });
            }
          },
        ),
        SettingsTile(
          title: const Text("WebSocket status"),
          description: Text(
              "${handler.getConnectionStatusMsg()} ${handler.connectionMsg} (Click to reconnect)"),
          leading: const Icon(Icons.private_connectivity),
          onPressed: (BuildContext context) async {
            if (await Permission.notification.isPermanentlyDenied) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Please enable notification permission")));
              }
              await openAppSettings();
            }
            if (await Permission.notification.isDenied) {
              await Permission.notification.request();
            }
            if (handler.connectionStatus != 1) {
              handler.init();
            }
          },
        ),
      ]),
      SettingsSection(title: const Text("Permissions"), tiles: [
        SettingsTile(
            title: const Text("Notification"),
            leading: const Icon(Icons.notifications),
            value: FutureBuilder(
                future: Permission.notification.isGranted,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  if (snapshot.data == null) {
                    return const Text("点击授权");
                  }
                  return Text(snapshot.data! ? "已授权" : "点击授权");
                }),
            onPressed: (BuildContext context) async {
              if (await Permission.notification.isPermanentlyDenied) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please enable notification permission")));
                }
                await openAppSettings();
              }
              if (await Permission.notification.isDenied) {
                await Permission.notification.request();
              }
              if (await Permission.notification.isGranted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Permission has been granted")));
              }
            }),
        SettingsTile(
          title: const Text("Background"),
          leading: const Icon(Icons.battery_4_bar),
          value: FutureBuilder(
              future: OptimizeBattery.isIgnoringBatteryOptimizations(),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (snapshot.data == null) {
                  return const Text("点击授权");
                }
                return Text(snapshot.data! ? "已授权" : "点击授权");
              }),
          onPressed: (BuildContext context) {
            OptimizeBattery.stopOptimizingBatteryUsage();
          },
        )
      ]),
    ]);
  }

  Future<String?> showInputDialog(
      BuildContext context, Text title, String hintText) async {
    TextEditingController controller = TextEditingController();
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: title,
            content: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: hintText)),
            actions: [
              MaterialButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              MaterialButton(
                child: const Text('Save'),
                onPressed: () {
                  Navigator.pop(context, controller.text);
                },
              ),
            ],
          );
        });
  }
}
