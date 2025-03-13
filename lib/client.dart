import 'dart:io';
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

  Future<String> readResponse(Stream<String> stream, StringBuffer buffer) async {
    bool gotWelcome = false;
    bool gotHeader = false;
    int bodyLength = 0;
    await for (final chunk in stream) {
      buffer.write(chunk); // 将接收到的数据块追加到缓冲区
      // 检查缓冲区中是否有完整的行
      if (!gotHeader){
        final current = buffer.toString();
        final lineEndIndex = current.indexOf('\n');
        if (lineEndIndex != -1) {
          if (!gotWelcome) {
            final remain = current.substring(lineEndIndex + 1); // 保留剩余的数据
            buffer.clear();
            buffer.write(remain);
            gotWelcome = true;
            continue;
          } else {
            final header = current.substring(0, lineEndIndex + 1);
            final remain = current.substring(lineEndIndex + 1); // 保留剩余的数据
            _logger.info("response header: $header");
            buffer.clear();
            buffer.write(remain);
            print('remain: $remain');
            gotHeader = true;
            bodyLength = int.parse(header.split(' ')[2]);
            if (remain.length>= bodyLength) {
              return remain;
            }
            continue;
          }
        }
      } else {
        if (buffer.length >= bodyLength) {
          return buffer.toString();
        }
      }
    }
    throw Exception('incomplete response');
  }

  Future<Object?> tcpJsonRpc(String method, {List<dynamic>? args}) async {
    String? ip = Settings.getValue(settingsKeyDaemonIp, defaultValue: "127.0.0.1");
    int port = 23333; // Assuming the TCP server is running on port 23332

    Map<String, dynamic> payload = {
      'jsonrpc': '2.0',
      'id': rpcRequestId,
      'method': method,
    };
    rpcRequestId++;
    if (args != null && args.isNotEmpty) {
      payload['params'] = args;
    }
    String body = jsonEncode(payload);
    String message = "jsonrpc '$body'\n";
    try {
      final socket = await Socket.connect(ip, port);
      socket.write(message);
      _logger.info('send tcp rpc request: $message');

      // Read the response header.
      final buffer = StringBuffer();
      final stream = utf8.decoder.bind(socket);
      final body = await readResponse(stream, buffer);
      _logger.info('received tcp rpc response: $body');
      socket.destroy();

      Map<String, dynamic> respBody = json.decode(body);
      return respBody['result'];
    } catch (e) {
      _logger.warning('tcp rpc failed, $e');
      return null;
    }
  }

  Future<Object?> jsonRpc(String method, {List<dynamic>? args}) async {
    return await tcpJsonRpc(method, args: args);

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

  /// Returns a list of songs.
  ///
  /// Each song is represented as a Map with the following structure:
  /// ```dart
  /// {
  ///    "identifier": "235474087",    // Unique identifier of the song
  ///    "source": "xxx",          // Source platform of the song
  ///    "title": "公路之歌 (Live)",     // Title of the song
  ///    "artists_name": "痛仰乐队",     // Name of the artist(s)
  ///    "album_name": "乐队的夏天 第11期", // Name of the album
  ///    "duration_ms": "05:07",       // Duration of the song
  ///    "provider": "xxx",        // Provider of the song
  ///    "uri": "fuo://xxx/songs/1111", // URI to access the song
  ///    "__type__": "feeluown.library.BriefSongModel" // Type identifier
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> listLibrarySongs() async {
    Object? obj = await jsonRpc("lambda: app.coll_mgr.get_coll_library().models");
    if (obj != null) {
      List<dynamic> list = obj as List<dynamic>;
      return list
          .where((item) =>
              item is Map<String, dynamic> &&
              item['__type__'] == 'feeluown.library.BriefSongModel')
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

  /// Returns a list of songs from the given album
  ///
  /// Each song is represented as a Map with the following structure:
  /// ```dart
  /// {
  ///    "identifier": "235474087",    // Unique identifier of the song
  ///    "source": "xxx",          // Source platform of the song
  ///    "title": "公路之歌 (Live)",     // Title of the song
  ///    "artists_name": "痛仰乐队",     // Name of the artist(s)
  ///    "album_name": "乐队的夏天 第11期", // Name of the album
  ///    "duration_ms": "05:07",       // Duration of the song
  ///    "provider": "xxx",        // Provider of the song
  ///    "uri": "fuo://xxx/songs/1111", // URI to access the song
  ///    "__type__": "feeluown.library.BriefSongModel" // Type identifier
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> listAlbumSongs(Map<String, dynamic> album) async {
    Object? obj = await jsonRpc("app.library.album_list_songs", args: [album]);
    if (obj != null) {
      List<dynamic> list = obj as List<dynamic>;
      return list
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    return [];
  }

  Future<void> playSong(Map<String, dynamic> song) async {
    await jsonRpc("app.playlist.play_model", args: [song]);
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
