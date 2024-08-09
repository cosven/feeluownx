import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class Client {
  // final String url = 'http://192.168.31.106:23332';
  final String url = 'http://10.0.2.2:23332';
  int rpcRequestId = 0;

  Future<Map<String, dynamic>?> jsonRpc(String method,
      {List<dynamic>? args}) async {
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
  // final String url = 'ws://192.168.31.106:23332/signal/v1';
  final String url = 'ws://10.0.2.2:23332/signal/v1';
  WebSocketChannel? channel;

  void connect() {
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
