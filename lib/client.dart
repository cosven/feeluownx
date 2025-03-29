import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:feeluownx/utils/websocket_utility.dart';
import 'package:intl/find_locale.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class Client {
  final _logger = Logger('Client');

  String host = "";
  String url = "";
  int rpcRequestId = 0;

  Client(String host_) {
    host = host_;
    url = "http://$host:23332";
  }

  void updateHost(String host_) {
    host = host_;
    url = "http://$host:23332";
    _logger.info("RPC host updated: $host");
  }

  Future<String> readResponse(
      Stream<String> stream, StringBuffer buffer) async {
    bool gotWelcome = false;
    bool gotHeader = false;
    int bodyLength = 0;
    await for (final chunk in stream) {
      buffer.write(chunk); // 将接收到的数据块追加到缓冲区
      // 检查缓冲区中是否有完整的行
      if (!gotHeader) {
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
            gotHeader = true;
            bodyLength = int.parse(header.split(' ')[2]);
            if (remain.length >= bodyLength) {
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

  Future<Object?> jsonRpc(String method, {List<dynamic>? args}) async {
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
    String message = "jsonrpc <<EOF\n$body\nEOF\n";
    try {
      // timeout is hardcoded to 3 seconds temporarily
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
      socket.write(message);
      _logger.info('Send RPC request: $message');

      // Read the response header.
      final buffer = StringBuffer();
      final stream = utf8.decoder.bind(socket);
      _logger.info('Waiting for response...');
      final body = await readResponse(stream, buffer);
      _logger.info('Received RPC response: $body');
      socket.destroy();

      Map<String, dynamic> respBody = json.decode(body);
      if (respBody.containsKey('error')) {
        final error = respBody['error'];
        _logger.severe('RPC error response: $error');
        throw Exception('RPC error: ${error['message']}');
      }
      return respBody['result'];
    } catch (e) {
      _logger.severe('RPC failed', e);
      throw Exception('RPC failed: $e');
    }
  }

  Future<Object?> httpJsonRpc(String method, {List<dynamic>? args}) async {
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
      if (respBody.containsKey('error')) {
        final error = respBody['error'];
        _logger.severe('HTTP RPC error response: $error');
        throw Exception('HTTP RPC error: ${error['message']}');
      }
      return respBody['result'];
    } else {
      _logger.severe('HTTP RPC failed with status: ${response.statusCode}');
      throw Exception('HTTP RPC failed with status: ${response.statusCode}');
    }
  }

  /// Returns a list of collections
  ///
  /// Each collection is represented as a Map with the following structure:
  /// ```dart
  /// {
  ///   "identifier": 12345,
  ///   "name": "我喜欢的音乐",
  ///   "models_count": 10
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> listCollections() async {
    Object? obj = await jsonRpc(
        "lambda: [{'identifier': c.identifier, 'name': c.name, 'models_count': len(c.models)}"
        " for c in app.coll_mgr.listall()]");
    List<dynamic> list = obj! as List<dynamic>;
    return list.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<void> collectionOverwrite(Map<String, dynamic> collection, String rawData) async {
    final identifier = collection['identifier'];
    await jsonRpc("app.coll_mgr.get($identifier).overwrite_with_raw_data", args: [rawData]);
    // Reload the collection to make sure the data is updated
    await jsonRpc("app.coll_mgr.get($identifier).load");
  }

  Future<void> collectionCreate(String name, String rawData) async {
    Object? obj = await jsonRpc("lambda: app.coll_mgr.create('$name', '$name').identifier");
    final identifier = (obj!) as int;
    // Let the collection manager know that the collection has been created.
    await jsonRpc("app.coll_mgr.refresh");
    // Reload the collection to make sure the data is updated
    await jsonRpc("app.coll_mgr.get($identifier).overwrite_with_raw_data", args: [rawData]);
  }

  /// Sync a collection from the remote server to the local server
  ///
  Future<int> collectionSyncToLocal(Map<String, dynamic> collection) async {
    final identifier = collection['identifier'];
    final name = collection['name'];
    Object? obj = await jsonRpc("app.coll_mgr.get($identifier).raw_data");
    String rawData = (obj!) as String;

    final localClient = Client('127.0.0.1');
    final localCollections = await localClient.listCollections();
    for (final localCollection in localCollections) {
      if (localCollection['name'] == name) {
        await localClient.collectionOverwrite(localCollection, rawData);
        return 200;
      }
    }
    await localClient.collectionCreate(name, rawData);
    return 201;
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
    Object? obj =
        await jsonRpc("lambda: app.coll_mgr.get_coll_library().models");
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
  Future<List<Map<String, dynamic>>> listCollectionSongs(
      String identifier) async {
    Object? obj = await jsonRpc("lambda: app.coll_mgr.get($identifier).models");
    return _filterSongs(obj! as List<dynamic>);
  }

  List<Map<String, dynamic>> _filterSongs(List<dynamic> list) {
    return list
        .where((item) =>
            item is Map<String, dynamic> &&
            item['__type__'] == 'feeluown.library.BriefSongModel')
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> listLibrarySongs() async {
    Object? obj =
        await jsonRpc("lambda: app.coll_mgr.get_coll_library().models");
    return _filterSongs(obj! as List<dynamic>);
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
  Future<List<Map<String, dynamic>>> listAlbumSongs(
      Map<String, dynamic> album) async {
    Object? obj = await jsonRpc("app.library.album_list_songs", args: [album]);
    if (obj != null) {
      List<dynamic> list = obj as List<dynamic>;
      return list.map((item) => item as Map<String, dynamic>).toList();
    }
    return [];
  }

  Future<void> playSong(Map<String, dynamic> song) async {
    await jsonRpc("app.playlist.play_model", args: [song]);
  }

  Future<void> playlistSetModels(List<Map<String, dynamic>> songs) async {
    await jsonRpc("app.playlist.set_models", args: [songs, true]);
  }

  Future<void> playlistClear() async {
    await jsonRpc("app.playlist.clear");
  }

  Future<void> playlistRemove(Map<String, dynamic> song) async {
    await jsonRpc("app.playlist.remove", args: [song]);
  }

  /// Returns a list of songs
  /// The song structure is the same as the one returned by listLibrarySongs
  Future<List<Map<String, dynamic>>> playlistList() async {
    Object? obj = await jsonRpc("app.playlist.list");
    return (obj! as List<dynamic>).map((item) => item as Map<String, dynamic>).toList();
  }

  /* ---------------------- */
  /* Player control methods */
  /* ---------------------- */

  Future<void> playerResume() async {
    await jsonRpc("app.player.resume");
  }

}

class PubsubClient {
  final _logger = Logger('PubsubClient');

  String host = "";
  WebSocketChannel? channel;

  PubsubClient(String host_) {
    host = host_;
  }

  void updateHost(String host_) async {
    host = host_;
  }

  Future<void> connect(
      {required Function onMessage, required Function onError}) async {
    final url = "ws://$host:23332/signal/v1";
    WebSocketUtility().initWebSocket(
        uri: url,
        onOpen: () {
          WebSocketUtility().initHeartBeat();
        },
        onMessage: (msg) {
          Map<String, dynamic> js = {};
          try {
            js = json.decode(msg);
          } catch (e) {
            _logger.severe('decode message failed: $e');
          }
          // compactible with TcpPubsubClient message
          onMessage(js);
        }, //onMessage,
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

Future<void> main() async {
  final client = Client("192.168.31.144");
  client.collectionCreate('test', '');
}
