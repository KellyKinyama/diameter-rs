// lib/transport/client.dart

import 'dart:async';
import '../diameter_rs.dart';
// import '../dictionary/dictionary.dart';
// import 'peer.dart';

/// A Diameter protocol client.
class DiameterClient {
  final Peer peer;
  int _hopByHopCounter = 0;
  final Map<int, Completer<DiameterMessage>> _pendingRequests = {};

  DiameterClient(String host, int port, Dictionary dict, RequestHandler handler)
    : peer = Peer(
        host: host,
        port: port,
        dict: dict,
        isClient: true,
        handler: handler,
      );

  /// Connects to the server and initiates the CER/CEA handshake.
  Future<void> connect() {
    return peer.connect();
  }

  /// Sends a Diameter message and returns a Future for the response.
  /// This should only be called after the peer state is OPEN.
  Future<DiameterMessage> sendRequest(DiameterMessage request) {
    if (peer.state != PeerState.open) {
      throw StateError(
        'Client is not in OPEN state. Current state: ${peer.state}',
      );
    }

    // Assign a unique Hop-by-Hop ID
    request.header.hopByHopId = ++_hopByHopCounter;

    final completer = Completer<DiameterMessage>();
    _pendingRequests[request.header.hopByHopId] = completer;

    // _socket!.add(request.encode());

    return completer.future;
    // A more robust implementation would queue requests and handle timeouts.
    // For now, we assume the application handler passed to the peer does this.
    // This is a simplified example.
    // return Future.value(DiameterMessage.create(0, 0, peer.dict)); // Placeholder
  }

  /// Closes the connection.
  void disconnect() {
    peer.disconnect();
  }
}
