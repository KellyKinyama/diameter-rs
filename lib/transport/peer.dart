// lib/transport/peer.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../diameter_rs.dart';
// import '../dictionary/dictionary.dart';
// import 'server.dart'; // For RequestHandler

enum PeerState { closed, waitConnAck, waitICea, open, closing }

class Peer {
  final String host;
  final int port;
  final Dictionary dict;
  final bool isClient;
  final RequestHandler handler;

  PeerState state = PeerState.closed;
  Socket? _socket;
  Timer? _tcTimer;
  Timer? _watchdogTimer;

  String? peerOriginHost;
  String? peerOriginRealm;

  Peer({
    required this.host,
    required this.port,
    required this.dict,
    required this.isClient,
    required this.handler,
  });

  Future<void> connect() async {
    if (state != PeerState.closed) return;

    print("Attempting to connect to peer $host:$port");
    state = PeerState.waitConnAck;
    try {
      _socket = await Socket.connect(host, port);
      print("Connected to $host:$port. Sending CER.");
      state = PeerState.waitICea;
      _tcTimer?.cancel();
      _socket!.listen(_handleData, onError: _handleError, onDone: _onDone);

      // FIXED: Call handler synchronously
      final cer = handler(
        DiameterMessage.create(
          CommandCode.capabilitiesExchange,
          ApplicationId.common,
          dict,
          flags: DiameterFlags.REQUEST,
        ),
      );
      _socket!.add(cer.encode());
      _startWatchdog();
    } catch (e) {
      print("Connection to $host:$port failed: $e");
      state = PeerState.closed;
      if (isClient) {
        _startTcTimer();
      }
    }
  }

  void accept(Socket socket) {
    if (state != PeerState.closed) {
      socket.destroy();
      return;
    }
    _socket = socket;
    print(
      "Accepted connection from ${socket.remoteAddress.address}:${socket.remotePort}",
    );
    _socket!.listen(_handleData, onError: _handleError, onDone: _onDone);
    _startWatchdog();
  }

  void _handleData(Uint8List data) {
    _resetWatchdog();
    try {
      final msg = DiameterMessage.decode(data, dict);

      if (msg.header.code == CommandCode.capabilitiesExchange) {
        if ((msg.header.flags & DiameterFlags.REQUEST) != 0) {
          handleCer(msg);
        } else {
          handleCea(msg);
        }
      } else if (msg.header.code == CommandCode.deviceWatchdog) {
        if ((msg.header.flags & DiameterFlags.REQUEST) != 0) {
          handleDwr(msg);
        } else {
          handleDwa(msg);
        }
      } else {
        if (state == PeerState.open) {
          // FIXED: Call handler synchronously
          final response = handler(msg);
          _socket?.add(response.encode());
        } else {
          print(
            "Received application message while not in OPEN state. Discarding.",
          );
        }
      }
    } catch (e) {
      print("Error decoding message: $e");
      disconnect();
    }
  }

  void handleCer(DiameterMessage cer) {
    print("Received CER from peer");
    final cea = handler(cer);
    _socket?.add(cea.encode());
    state = PeerState.open;
    print("Peer state is now OPEN.");
  }

  void handleCea(DiameterMessage cea) {
    if (state == PeerState.waitICea) {
      final resultCode = cea.getResultCode();
      if (resultCode == ResultCode.DIAMETER_SUCCESS) {
        print("Received successful CEA. Peer state is now OPEN.");
        state = PeerState.open;
      } else {
        print("Received CEA with error code $resultCode. Disconnecting.");
        disconnect();
      }
    }
  }

  void handleDwr(DiameterMessage dwr) {
    final dwa = handler(dwr);
    _socket?.add(dwa.encode());
  }

  void handleDwa(DiameterMessage dwa) {
    print("Received DWA from peer.");
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (_socket != null && state == PeerState.open) {
        print("Watchdog fired. Sending DWR.");
        final dwr = handler(
          DiameterMessage.create(
            CommandCode.deviceWatchdog,
            ApplicationId.common,
            dict,
            flags: DiameterFlags.REQUEST,
          ),
        );
        _socket!.add(dwr.encode());
      }
    });
  }

  void _resetWatchdog() {
    _startWatchdog();
  }

  void _startTcTimer() {
    if (_tcTimer != null && _tcTimer!.isActive) return;
    print("Starting Tc Timer for reconnection.");
    _tcTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (state == PeerState.closed) {
        connect();
      }
    });
  }

  void _handleError(error) {
    print('Socket error for peer $host: $error');
    disconnect();
  }

  void _onDone() {
    print('Connection closed for peer $host.');
    disconnect();
  }

  void disconnect() {
    state = PeerState.closed;
    _socket?.destroy();
    _socket = null;
    _watchdogTimer?.cancel();
    if (isClient) {
      _startTcTimer();
    }
  }
}
