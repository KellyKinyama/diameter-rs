// lib/transport/server.dart

import 'dart:io';
// import '../protocol/diameter_message.dart';
// import '../dictionary/dictionary.dart';
// import 'peer.dart';
import '../diameter_rs.dart';

typedef RequestHandler = DiameterMessage Function(DiameterMessage request);

/// A Diameter protocol server.
class DiameterServer {
  final String host;
  final int port;
  final Dictionary dict;
  final RequestHandler handler;

  ServerSocket? _serverSocket;
  final Map<String, Peer> peers = {};

  DiameterServer(this.host, this.port, this.dict, this.handler);

  /// Starts the server and listens for incoming connections.
  Future<void> listen() async {
    _serverSocket = await ServerSocket.bind(host, port);
    print('Diameter server listening on ${host}:${port}...');

    _serverSocket!.listen((socket) {
      // Create a temporary peer object to handle the initial CER
      final tempPeer = Peer(
        host: socket.remoteAddress.address,
        port: socket.remotePort,
        dict: dict,
        isClient: false,
        handler: _handleRequest,
      );
      tempPeer.accept(socket);
      // Once CER is received, it will be moved to the main `peers` map.
    });
  }

  /// This is the main request router for the server.
  DiameterMessage _handleRequest(DiameterMessage request) {
    // Identify the peer by its Origin-Host
    final originHostAvp = request.getAvp(AvpCode.OriginHost);
    if (originHostAvp == null) {
      // This is a protocol error, but for simplicity we close the connection.
      // A full implementation would return an error message.
      throw DiameterException.protocol("Request is missing Origin-Host");
    }
    final peerIdentity = originHostAvp.value.toString();

    // Now, route the request to the application-specific handler
    return handler(request);
  }

  /// Stops the server.
  void close() {
    _serverSocket?.close();
    peers.forEach((_, peer) => peer.disconnect());
  }
}
