import 'dart:convert';

import 'package:feeluownx/utils/websocket_utility.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class Client {
  static const String settingsKeyDaemonIp = "settings_ip_address";
  final _logger = Logger('Client');

  String url = "";
  int rpcRequestId = 0;

  Client() {
    initClient();
  }

  Future<void> initClient() async {
    String? ip =
        Settings.getValue(settingsKeyDaemonIp, defaultValue: "127.0.0.1");
    url = "http://$ip:23332";
  }

  void reloadSettings() {
    String? ip =
        Settings.getValue(settingsKeyDaemonIp, defaultValue: "127.0.0.1");
    url = "http://$ip:23332";
    _logger.info("url: $url");
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
    rpcRequestId++;
    _logger.info('send rpc request: $body');
    if (response.statusCode == 200) {
      Map<String, dynamic> respBody = json.decode(response.body);
      return respBody['result'];
    } else {
      _logger.warning('rpc failed, $response');
    }
    return null;
  }

  /// Returns a list of albums from the library
  ///
  /// Each album is represented as a Map with the following structure:
  /// ```dart
  /// {
  ///   "identifier": "8220",
  ///   "source": "xxx",
  ///   "name": "叶惠美",
  ///   "artists_name": "周杰伦",
  ///   "provider": "qqmusic",
  ///   "uri": "fuo://xxx/albums/8220",
  ///   "__type__": "feeluown.library.BriefAlbumModel"
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> listLibraryAlbums() async {
    Object? obj = await jsonRpc("lambda: app.coll_mgr.get_coll_library().models");
    if (obj != null) {
      List<dynamic> list = obj as List<dynamic>;
      return list
          .where((item) =>
              item is Map<String, dynamic> &&
              item['__type__'] == 'feeluown.library.BriefAlbumModel')
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    return [];
  }

  Future<String?> getAlbumCover(Map<String, dynamic> album) async {
    Object? obj = await jsonRpc("app.library.album_upgrade", args: [album]);
    if (obj != null) {
      return (obj as Map<String, dynamic>)['cover'];
    }
    return null;
  }
}

class PubsubClient {
  static const String settingsKeyDaemonIp = "settings_ip_address";
  final _logger = Logger('PubsubClient');

  String url = "";
  WebSocketChannel? channel;

  Future<void> initClient() async {
    String? ip =
        Settings.getValue(settingsKeyDaemonIp, defaultValue: "127.0.0.1");
    url = "ws://$ip:23332/signal/v1";
  }

  Future<void> connect(
      {required Function onMessage, required Function onError}) async {
    await initClient();
    WebSocketUtility().initWebSocket(
        uri: url,
        onOpen: () {
          WebSocketUtility().initHeartBeat();
        },
        onMessage: onMessage,
        onError: onError);
    channel = WebSocketChannel.connect(Uri.parse(url));
  }

  void close() {
    channel?.sink.close();
  }

  Stream<dynamic>? get stream => channel?.stream;

  void send(String message) {
    WebSocketUtility().sendMessage(message);
  }
}
