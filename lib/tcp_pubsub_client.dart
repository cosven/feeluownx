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
  bool _isConnecting = false;

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
    if (_isConnected || _isConnecting) {
      _logger.info("Already connected or connecting, skipping reconnect");
      return;
    }
    _isConnecting = true;
    _notifyConnectionState(false);

    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        await _connectInternal();
        _isConnecting = false;
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
    _isConnecting = false;
    throw Exception('Failed to connect after $maxRetries attempts');
  }

  Future<void> _connectInternal() async {
    assert(!_isConnected);
    close(); // Clean up any existing connection
    _notifyConnectionState(false); // Notify disconnection first

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
    _notifyConnectionState(true);

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
        _isConnected = false;
        for (var callback in _onErrorCallbacks) {
          callback(error);
        }
      },
      onDone: () {
        _logger.info('Stream closed');
        _isConnected = false;
        _notifyConnectionState(false);
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
    _isConnecting = false;
    _socket?.destroy();
    _socket = null;
    _streamController?.close();
    _streamController = null;
    _broadcastStream = null;
  }

  /// Returns whether the client is currently connected to the server
  bool get isConnected => _isConnected;

  /// Returns the current connection status as a string for display purposes
  String get connectionStatus => _isConnecting 
      ? 'Connecting...' 
      : _isConnected ? 'Connected' : 'Disconnected';

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

  void addConnectionStateListener(Function(bool) callback) {
    _onConnectionStateCallbacks.add(callback);
  }

  void removeConnectionStateListener(Function(bool) callback) {
    _onConnectionStateCallbacks.remove(callback);
  }

  void _notifyConnectionState(bool connected) {
    for (var callback in _onConnectionStateCallbacks) {
      callback(connected);
    }
  }
}
