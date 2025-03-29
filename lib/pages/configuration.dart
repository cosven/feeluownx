import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:optimize_battery/optimize_battery.dart';
import 'package:permission_handler/permission_handler.dart';

import '../global.dart';
import '../player.dart';
import '../client.dart';
import '../tcp_pubsub_client.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<StatefulWidget> createState() => ConfigurationPageState();
}

class ConfigurationPageState extends State<ConfigurationPage> {
  final AudioPlayerHandler handler = Global.getIt<AudioPlayerHandler>();
  final Client client = Global.getIt<Client>();
  final TcpPubsubClient pubsubClient = Global.getIt<TcpPubsubClient>();

  static const String settingsKeyDaemonIp = "settings_ip_address";

  static const startInTermux = MethodChannel('channel.feeluown/termux');

  String connectionStatus = "";

  @override
  void initState() {
    super.initState();
    pubsubClient.addConnectionStateListener((connected) {
      // Use the connectionStatus getter which handles all states
      subCallback(pubsubClient.connectionStatus);
    });
    // Initialize with current status
    subCallback(pubsubClient.connectionStatus);
  }

  @override
  void dispose() {
    pubsubClient.removeConnectionStateListener((connected) {
      subCallback(connected ? 'Connected' : 'Disconnected');
    });
    super.dispose();
  }

  void subCallback(String msg) {
    if (!mounted) return;
    setState(() {
      connectionStatus = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      SettingsGroup(title: "General", children: [
        TextInputSettingsTile(
          title: "Instance IP",
          helperText: "The IP Address of FeelUOwn daemon",
          settingKey: settingsKeyDaemonIp,
          initialValue: "127.0.0.1",
          onChange: (host_) {
            client.updateHost(host_);
            pubsubClient.updateHost(host_);
            pubsubClient.connect();
          },
        ),
        SimpleSettingsTile(
          title: "Connection Status",
          subtitle: connectionStatus.isEmpty 
              ? "Loading..." 
              : "$connectionStatus (Click to reconnect)",
          leading: const Icon(Icons.private_connectivity),
          onTap: () async {
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
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Try connecting...")));
            }
            pubsubClient.connect();
          },
        )
      ]),
    ];
    if (Platform.isAndroid || Platform.isIOS) {
      // show permission section only on supported platform
      children.add(SettingsGroup(title: "Permission", children: [
        FutureBuilder(
            future: Permission.notification.isGranted,
            builder: (context, snapshot) {
              String subtitle = "点击授权";
              if (snapshot.data != null && snapshot.data!) {
                subtitle = "已授权";
              }
              return SimpleSettingsTile(
                title: "Notification",
                leading: const Icon(Icons.notifications),
                subtitle: subtitle,
                onTap: () async {
                  if (await Permission.notification.isPermanentlyDenied) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text("Please enable notification permission")));
                    }
                    await openAppSettings();
                    setState(() {});
                  }
                  if (await Permission.notification.isDenied) {
                    await Permission.notification.request();
                    setState(() {});
                  }
                  if (await Permission.notification.isGranted &&
                      context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Permission has been granted")));
                  }
                },
              );
            }),
        FutureBuilder(
            future: OptimizeBattery.isIgnoringBatteryOptimizations(),
            builder: (context, snapshot) {
              String subtitle = "点击授权";
              if (snapshot.data != null && snapshot.data!) {
                subtitle = "已授权";
              }
              return SimpleSettingsTile(
                title: "Background",
                leading: const Icon(Icons.battery_4_bar),
                subtitle: subtitle,
                onTap: () async {
                  await OptimizeBattery.stopOptimizingBatteryUsage();
                  setState(() {});
                },
              );
            }),
      ]));
    }
    if (Platform.isAndroid) {
      children.add(SettingsGroup(title: "Android", children: [
        SimpleSettingsTile(
            title: "Run in Termux",
            leading: const Icon(Icons.restart_alt),
            onTap: () async {
              try {
                await startInTermux.invokeMethod<void>('startInTermux');
              } on PlatformException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to run in Termux")));
                }
              }
            })
      ]));
    }
    return SettingsScreen(children: children);
  }
}
