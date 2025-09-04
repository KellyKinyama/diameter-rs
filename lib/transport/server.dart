// lib/transport/server.dart

import 'dart:io';
import 'dart:typed_data';
// import '../protocol/diameter_message.dart';
// import '../dictionary/dictionary.dart';
import '../diameter_rs.dart';
typedef RequestHandler = Future<DiameterMessage> Function(DiameterMessage request);

/// A Diameter protocol server.
class DiameterServer {
  final String host;
  final int port;
  final Dictionary dict;
  final RequestHandler handler;
  
  ServerSocket? _serverSocket;

  DiameterServer(this.host, this.port, this.dict, this.handler);

  /// Starts the server and listens for incoming connections.
  Future<void> listen() async {
    _serverSocket = await ServerSocket.bind(host, port);
    print('Diameter server listening on ${host}:${port}...');
    
    _serverSocket!.listen((socket) {
      print('Accepted connection from ${socket.remoteAddress.address}:${socket.remotePort}');
      _handleConnection(socket);
    });
  }

  void _handleConnection(Socket socket) {
    socket.listen(
      (Uint8List data) async {
        try {
          // In a real implementation, a Codec would handle framing
          final request = DiameterMessage.decode(data, dict);
          final response = await handler(request);
          socket.add(response.encode());
        } catch (e) {
          print('Error processing message: $e');
          socket.close();
        }
      },
      onError: (error) {
        print('Connection error: $error');
        socket.close();
      },
      onDone: () {
        print('Connection closed.');
      }
    );
  }

  /// Stops the server.
  void close() {
    _serverSocket?.close();
  }
}