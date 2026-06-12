import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ChatSocketSession {
  final WebSocket _socket;
  final StreamController<Map<String, dynamic>> _events;
  final String sessionId;

  bool _closed = false;

  ChatSocketSession._(this._socket, this._events, this.sessionId);

  Stream<Map<String, dynamic>> get events => _events.stream;

  static Future<ChatSocketSession?> connect({
    required Uri webBaseUri,
    required String token,
  }) async {
    if (token.isEmpty) return null;

    final socketUri = _socketUri(webBaseUri);
    final socket = await WebSocket.connect(
      socketUri.toString(),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    final events = StreamController<Map<String, dynamic>>.broadcast();
    final connected = Completer<String>();
    String? engineSessionId;

    socket.listen(
      (message) {
        final packet = _messageToString(message);
        if (packet == null || packet.isEmpty) return;

        if (packet == '2') {
          socket.add('3');
          return;
        }

        if (packet.startsWith('0')) {
          final openPayload = _decodeMap(packet.substring(1));
          engineSessionId = openPayload?['sid']?.toString();
          socket.add('40${jsonEncode({'token': token})}');
          return;
        }

        if (packet.startsWith('40')) {
          final connectPayload = packet.substring(2).trim();
          final connectData =
              connectPayload.isEmpty ? null : _decodeMap(connectPayload);
          final socketSessionId =
              connectData?['sid']?.toString() ?? engineSessionId;
          if (socketSessionId != null && !connected.isCompleted) {
            connected.complete(socketSessionId);
            socket
                .add('42["user-join",{"auth":{"token":${jsonEncode(token)}}}]');
          }
          return;
        }

        if (packet.startsWith('42')) {
          final parsedEvent = _parseEventPacket(packet);
          if (parsedEvent == null) return;

          final data = parsedEvent.data;
          if (parsedEvent.name == 'chat-events' &&
              data is Map<String, dynamic>) {
            events.add(data);
          }

          if (parsedEvent.ackId != null) {
            socket.add('43${parsedEvent.ackId}[null]');
          }
          return;
        }

        if (packet.startsWith('44') && !connected.isCompleted) {
          connected.completeError(
            StateError('Socket.IO connection rejected: ${packet.substring(2)}'),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!connected.isCompleted) {
          connected.completeError(error, stackTrace);
        }
        if (!events.isClosed) {
          events.addError(error, stackTrace);
          unawaited(events.close());
        }
      },
      onDone: () {
        if (!connected.isCompleted) {
          connected
              .completeError(StateError('Socket closed before connecting'));
        }
        if (!events.isClosed) {
          unawaited(events.close());
        }
      },
      cancelOnError: true,
    );

    try {
      final sessionId = await connected.future.timeout(
        const Duration(seconds: 10),
      );
      if (kDebugMode) {
        debugPrint('chat socket connected: sessionId=$sessionId');
      }
      return ChatSocketSession._(socket, events, sessionId);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('chat socket connect failed: $error');
      }
      await socket.close();
      if (!events.isClosed) {
        await events.close();
      }
      return null;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      _socket.add('41');
    } catch (_) {
      // Socket may already be closing.
    }
    await _socket.close();
    if (!_events.isClosed) {
      await _events.close();
    }
  }

  static Uri _socketUri(Uri webBaseUri) {
    final scheme = webBaseUri.scheme == 'https' ? 'wss' : 'ws';
    return webBaseUri.replace(
      scheme: scheme,
      path: '/ws/socket.io/',
      queryParameters: {
        'EIO': '4',
        'transport': 'websocket',
      },
    );
  }

  static String? _messageToString(dynamic message) {
    if (message is String) return message;
    if (message is List<int>) return utf8.decode(message);
    return null;
  }

  static Map<String, dynamic>? _decodeMap(String source) {
    try {
      final decoded = jsonDecode(source);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static _SocketEvent? _parseEventPacket(String packet) {
    final payloadStart = packet.indexOf('[');
    if (payloadStart == -1) return null;

    final ackIdSource = packet.substring(2, payloadStart);
    final ackId = ackIdSource.isEmpty ? null : ackIdSource;
    final payload = packet.substring(payloadStart);

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! List || decoded.isEmpty) return null;
      final name = decoded.first?.toString();
      if (name == null || name.isEmpty) return null;
      final data = decoded.length > 1 ? decoded[1] : null;
      return _SocketEvent(name: name, data: data, ackId: ackId);
    } catch (_) {
      return null;
    }
  }
}

class _SocketEvent {
  final String name;
  final dynamic data;
  final String? ackId;

  _SocketEvent({
    required this.name,
    required this.data,
    required this.ackId,
  });
}
