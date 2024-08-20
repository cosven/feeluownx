import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class Client {
  static const String settingsKeyDaemonIp = "settings_ip_address";
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  String url = "";
  int rpcRequestId = 0;

  Client() {
    initClient();
  }

  Future<void> initClient() async {
    String? ip =
        (await prefs.getString(settingsKeyDaemonIp)) ?? "127.0.0.1";
    url = "http://$ip:23332";
  }

  Future<Object?> jsonRpc(String method, {List<dynamic>? args}) async {
    Map<String, dynamic> payload = {
      'jsonrpc': '2.0',
      'id': rpcRequestId,
      'method': method,
    };
    if (args != null && args.isNotEmpty) {
      payload['params'] = args;
    }
    String body = jsonEncode(payload);
    final response = await http.post(
      Uri.parse('$url/rpc/v1'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );
    rpcRequestId ++;
    print('send rpc request: $body');
    if (response.statusCode == 200) {
      Map<String, dynamic> respBody = json.decode(response.body);
      return respBody['result'];
    } else {
      print('rpc failed, $response');
    }
    return null;
  }
}

class PubsubClient {
  static const String settingsKeyDaemonIp = "settings_ip_address";
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  String url = "";
  WebSocketChannel? channel;

  Future<void> initClient() async {
    String? ip =
        (await prefs.getString(settingsKeyDaemonIp)) ?? "127.0.0.1";
    url = "ws://$ip:23332/signal/v1";
  }

  Future<void> connect() async {
    await initClient();
    channel = WebSocketChannel.connect(Uri.parse(url));
  }

  void close() {
    channel?.sink.close();
  }

  Stream<dynamic>? get stream => channel?.stream;

  void send(String message) {
    channel?.sink.add(message);
  }
}
