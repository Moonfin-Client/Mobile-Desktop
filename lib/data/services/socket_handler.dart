import 'dart:async';

import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:server_core/server_core.dart';

class SocketHandler {
  final MediaServerClient _client;
  final _logger = Logger();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  SocketHandler(this._client);

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void connect() {
    final wsUrl = _client.baseUrl
        .replaceFirst('http', 'ws');
    final token = _client.accessToken ?? '';

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/socket?api_key=$token'),
      );

      _subscription = _channel!.stream.listen(
        (data) {
          _logger.d('WebSocket event received');
        },
        onError: (error) {
          _logger.e('WebSocket error', error: error);
        },
        onDone: () {
          _logger.i('WebSocket closed');
        },
      );
    } catch (e) {
      _logger.e('WebSocket connection failed', error: e);
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
