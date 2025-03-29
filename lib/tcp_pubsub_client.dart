import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:logging/logging.dart';

class TcpPubsubClient {
  final _logger = Logger('TcpPubsubClient');

  String host = "127.0.0.1";
  int port = 23334;
  Socket? _socket;
  StreamController<String>? _streamController;
  Stream<String>? _broadcastStream;
  bool _isConnected = false;

  final List<Function> _onMessageCallbacks = [];
  final List<Function> _onErrorCallbacks = [];

  TcpPubsubClient(String host_) {
    host = host_;
  }

  updateHost(String host_) {
    host = host_;
  }

  void tryConnect() {
    tcpPubsubClient.close();
    _logger.info('Trying to subscribe messages');
    tcpPubsubClient.connect(onMessage: (message) async {
      await handleMessage(message);
    }, onError: (e) {
      final connectionMsg = "Error: ${e.toString()}";
      if (callback != null) {
        callback(connectionMsg);
      }
      _logger.severe('Pubsub error: $e');
    }).then((_) {
      const connectionMsg = "Connected!";
      if (callback != null) {
        callback(connectionMsg);
      }
      _logger.info(connectionMsg);
      initPlaybackState();
      initFuoCurrentPlayingInfo();
    }).catchError((error) {
      final errmsg = error.toString();
      final connectionMsg = "Connection failed, retrying in 2 second...\n$errmsg";
      if (callback != null) {
        callback(connectionMsg);
      }
      _logger.severe('Pubsub connection failed: $error');
      Future.delayed(
          Duration(seconds: 2), () => trySubscribeMessages(callback));
    });
  }

  // FIXME: the protocol parser is hacky and not robust
  Future<void> connect({
    required Function onMessage,
    required Function onError,
  }) async {
    if (_isConnected) {
      await _socket!.close();
    }

    _onMessageCallbacks.add(onMessage);
    _onErrorCallbacks.add(onError);

    // Connect to the server
    try {
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 1));
    } catch (e) {
      _logger.severe('Failed to connect to $host:$port: $e');
      for (var callback in _onErrorCallbacks) {
        callback(e);
      }
      rethrow;
    }

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
    _socket?.write('sub player.*\n');

    // Start listening for messages
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
          for (var callback in _onErrorCallbacks) {
            callback(e);
          }
        }
      },
      onError: (error) {
        _logger.severe('Stream error: $error');
        _isConnected = false;
        for (var callback in _onErrorCallbacks) {
          callback(error);
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

    // Call all onMessage callbacks
    for (var callback in _onMessageCallbacks) {
      callback(message);
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

  void addMessageListener(Function callback) {
    _onMessageCallbacks.add(callback);
  }

  void removeMessageListener(Function callback) {
    _onMessageCallbacks.remove(callback);
  }

  void addErrorListener(Function callback) {
    _onErrorCallbacks.add(callback);
  }

  void removeErrorListener(Function callback) {
    _onErrorCallbacks.remove(callback);
  }

  void unsubscribe(String topic) {
    if (!_isConnected || _socket == null) {
      _logger.warning('Cannot unsubscribe, not connected');
      return;
    }
    _socket!.write('unsub $topic\n');
  }
}
