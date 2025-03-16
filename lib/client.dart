import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:feeluownx/utils/websocket_utility.dart';
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
      final socket = await Socket.connect(host, port);
      socket.write(message);
      _logger.info('send tcp rpc request: $message');

      // Read the response header.
      final buffer = StringBuffer();
      final stream = utf8.decoder.bind(socket);
      final body = await readResponse(stream, buffer);
      _logger.info('received tcp rpc response: $body');
      socket.destroy();

      Map<String, dynamic> respBody = json.decode(body);
      if (respBody.containsKey('error')) {
        final error = respBody['error'];
        _logger.severe('RPC error response: $error');
        throw Exception('RPC error: ${error['message']}');
      }
      return respBody['result'];
    } catch (e) {
      _logger.severe('tcp rpc failed', e);
      throw Exception('RPC call failed: $e');
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
        "lambda: [{'id': c.identifier, 'name': c.name, 'models_count': len(c.models)}"
        " for c in app.coll_mgr.listall()]");
    List<dynamic> list = obj! as List<dynamic>;
    return list.map((item) => item as Map<String, dynamic>).toList();
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
  Future<List<Map<String, dynamic>>> listCollectionSongs(String identifier) async {
    Object? obj =
        await jsonRpc("lambda: app.coll_mgr.get($identifier).models");
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
}

class TcpPubsubClient {
  final _logger = Logger('TcpPubsubClient');

  String host = "127.0.0.1";
  int port = 23334;
  Socket? _socket;
  StreamController<String>? _streamController;
  Stream<String>? _broadcastStream;
  bool _isConnected = false;

  Function? _onMessage;
  Function? _onError;

  TcpPubsubClient(String host_) {
    host = host_;
  }

  updateHost(String host_) {
    host = host_;
  }

  // FIXME: the protocol parser is hacky and not robust
  Future<void> connect({
    required Function onMessage,
    required Function onError,
  }) async {
    if (_isConnected) {
      await _socket!.close();
    }

    _onMessage = onMessage;
    _onError = onError;

    try {
      // Connect to the server
      _socket = await Socket.connect(host, port);

      // Create a broadcast stream that can be listened to multiple times
      _streamController = StreamController<String>();
      utf8.decoder.bind(_socket!).transform(const LineSplitter()).listen(
            (data) => _streamController!.add(data),
            onError: (e) => _streamController!.addError(e),
            onDone: () => _streamController!.close(),
          );
      _broadcastStream = _streamController!.stream.asBroadcastStream();
      _isConnected = true;

      // Process the welcome message
      String? welcomeMessage = await _broadcastStream!.first;
      _logger.info('Received welcome message: $welcomeMessage');

      // Send version message
      _socket?.write('set --pubsub-version 2.0\n');
      String? versionResponse = await _broadcastStream!.first;
      _logger.info('Received version response: $versionResponse');

      // Subscribe to player.metadata_changed
      _socket?.write('sub player.metadata_changed\n');

      // Start listening for messages
      _startListening();
    } catch (e) {
      _isConnected = false;
      _logger.severe('Failed to connect: $e');
      onError(e);
    }
  }

  void _startListening() {
    if (_broadcastStream == null) return;

    _broadcastStream!.listen(
      (data) {
        try {
          if (data.startsWith('MSG')) {
            _processMessage(data);
          } else {
            _logger.info('Received other message: $data');
          }
        } catch (e) {
          _logger.warning('Error processing message: $e');
          if (_onError != null) {
            _onError!(e);
          }
        }
      },
      onError: (error) {
        _logger.severe('Stream error: $error');
        _isConnected = false;
        if (_onError != null) {
          _onError!(error);
        }
      },
      onDone: () {
        _logger.info('Stream closed');
        _isConnected = false;
      },
    );
  }

  Future<void> _processMessage(String headerLine) async {
    // Parse the header line: MSG {topic} {body_length}
    List<String> parts = headerLine.split(' ');
    if (parts.length < 3) {
      _logger.warning('Invalid message header: $headerLine');
      return;
    }

    String topic = parts[1];
    int bodyLength = int.parse(parts[2]);

    // Read the body
    String body = await _readBody(bodyLength);

    // Create a message object
    Map<String, dynamic> message = {
      'topic': topic,
      'data': body,
      'format': 'json',
    };

    // Call the onMessage callback
    if (_onMessage != null) {
      _onMessage!(message);
    }
  }

  Future<String> _readBody(int length) async {
    // This is a simplified approach - in a real implementation,
    // you would need to handle cases where the body spans multiple lines
    // or is split across multiple TCP packets
    String? line = await _broadcastStream?.first;
    return line ?? '';
  }

  void close() {
    _isConnected = false;
    _socket?.destroy();
    _socket = null;
    _streamController?.close();
    _streamController = null;
    _broadcastStream = null;
  }

  bool get isConnected => _isConnected;

  void subscribe(String topic) {
    if (!_isConnected || _socket == null) {
      _logger.warning('Cannot subscribe, not connected');
      return;
    }
    _socket!.write('sub $topic\n');
  }

  void unsubscribe(String topic) {
    if (!_isConnected || _socket == null) {
      _logger.warning('Cannot unsubscribe, not connected');
      return;
    }
    _socket!.write('unsub $topic\n');
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
  final client = Client("192.168.31.143");
  print(client.listCollections());
}
