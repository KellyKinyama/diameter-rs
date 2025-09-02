// lib/transport/client.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../protocol/diameter_message.dart';
import '../dictionary/dictionary.dart';
import 'codec.dart';

/// A Diameter protocol client.
class DiameterClient {
  final String host;
  final int port;
  final Dictionary dict;
  
  Socket? _socket;
  final Map<int, Completer<DiameterMessage>> _pendingRequests = {};
  int _hopByHopCounter = 0;

  DiameterClient(this.host, this.port, this.dict);

  /// Connects to the server and starts listening for responses.
  Future<void> connect() async {
    _socket = await Socket.connect(host, port);
    _socket!.listen(
      _handleData,
      onError: _handleError,
      onDone: disconnect,
    );
  }

  /// Sends a Diameter message and returns a Future for the response.
  Future<DiameterMessage> sendRequest(DiameterMessage request) {
    if (_socket == null) {
      throw StateError('Client is not connected.');
    }
    
    // Assign a unique Hop-by-Hop ID
    request.header.hopByHopId = ++_hopByHopCounter;
    
    final completer = Completer<DiameterMessage>();
    _pendingRequests[request.header.hopByHopId] = completer;

    _socket!.add(request.encode());
    
    return completer.future;
  }

  void _handleData(Uint8List data) {
    // The codec would handle message framing
    final message = DiameterMessage.decode(data, dict);
    final hopByHopId = message.header.hopByHopId;

    if (_pendingRequests.containsKey(hopByHopId)) {
      _pendingRequests[hopByHopId]!.complete(message);
      _pendingRequests.remove(hopByHopId);
    }
  }

  void _handleError(error) {
    print('Socket error: $error');
    disconnect();
  }

  /// Closes the connection.
  void disconnect() {
    _socket?.close();
    _socket = null;
    _pendingRequests.forEach((_, completer) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Connection closed'));
      }
    });
    _pendingRequests.clear();
  }
}