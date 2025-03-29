import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:logging/logging.dart';

enum ConnectionState { disconnected, connecting, connected }

class TcpPubsubClient {
  final _logger = Logger('TcpPubsubClient');

  String host = "127.0.0.1";
  int port = 23334;
  Socket? _socket;
  StreamController<String>? _streamController;
  Stream<String>? _broadcastStream;
  ConnectionState _connectionState = ConnectionState.disconnected;

  void _setConnectionState(ConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _notifyConnectionState(newState);
    }
  }

  final List<Function> _onMessageCallbacks = [];
  final List<Function> _onErrorCallbacks = [];
  final List<Function(bool)> _onConnectionStateCallbacks = [];

  TcpPubsubClient(String host_) {
    host = host_;
  }

  updateHost(String host_) {
    host = host_;
  }

  // FIXME: the protocol parser is hacky and not robust
  Future<void> connect({
    int maxRetries = 5,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    if (_connectionState != ConnectionState.disconnected) {
      _logger.info("Already connected or connecting, skipping reconnect");
      return;
    }

    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        await _connectInternal();
        _logger.info("Connected!");
        return;
      } catch (error) {
        retryCount++;
        _logger.severe('Pubsub connection failed (attempt $retryCount/$maxRetries): $error');
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }
    _setConnectionState(ConnectionState.disconnected);
    throw Exception('Failed to connect after $maxRetries attempts');
  }

  Future<void> _connectInternal() async {
    _setConnectionState(ConnectionState.connecting);
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
    _setConnectionState(ConnectionState.connected);

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
          _logger.severe('Error processing message: $e');
        }
      },
      onError: (error) {
        _logger.severe('Stream error: $error');
        _setConnectionState(ConnectionState.disconnected);
        for (var callback in _onErrorCallbacks) {
          callback(error);
        }
      },
      onDone: () {
        _logger.info('Stream closed');
        _setConnectionState(ConnectionState.disconnected);
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
    _setConnectionState(ConnectionState.disconnected);
    _socket?.destroy();
    _socket = null;
    _streamController?.close();
    _streamController = null;
    _broadcastStream = null;
  }

  /// Returns the current connection status as a string for display purposes
  String get connectionStatus {
    switch (_connectionState) {
      case ConnectionState.connecting:
        return 'Connecting...';
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  void subscribe(String topic) {
    if (_connectionState != ConnectionState.connected || _socket == null) {
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

  void addConnectionStateListener(Function(bool) callback) {
    _onConnectionStateCallbacks.add(callback);
  }

  void removeConnectionStateListener(Function(bool) callback) {
    _onConnectionStateCallbacks.remove(callback);
  }

  void _notifyConnectionState(ConnectionState state) {
    for (var callback in _onConnectionStateCallbacks) {
      callback(state == ConnectionState.connected);
    }
  }
}
