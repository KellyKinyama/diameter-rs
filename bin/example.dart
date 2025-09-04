// bin/example.dart
import 'dart:io';

import 'package:diameter_rs/diameter_rs.dart';
// import 'package:diameter/protocol/diameter_message.dart';
// import 'package:diameter/dictionary/dictionary.dart';
// import 'package:diameter/applications/base_application.dart';
// import 'package:diameter/transport/server.dart';
// import 'package:diameter/transport/client.dart';
// import 'package:diameter/transport/peer.dart';

// // Import your dictionary file
// import 'package:diameter/dictionary/default_dictionary_xml.dart';

void main() async {
  // Load the dictionary from your XML string constant.
  print("Loading dictionary from your provided XML...");
  final dict = Dictionary.load([defaultDictXml]);
  print("Dictionary loaded successfully.");

  final serverHost = '127.0.0.1';
  final clientHost = '127.0.0.1'; // Explicitly define for clarity
  final serverPort = 3868;

  // --- Server Setup ---
  // FIXED: Added the 4th argument 'serverHost' for the IP address.
  final serverBaseHandler = BaseApplicationHandler(
    dict,
    'server.example.com',
    'example.com',
    serverHost,
  );

  // This handler function will be called by the Peer object for incoming messages.
  DiameterMessage serverHandler(DiameterMessage request) {
    print(
      "Server received message with App-ID: ${request.header.applicationId}, Command-Code: ${request.header.code}",
    );
    if (request.header.applicationId == ApplicationId.common.id) {
      return serverBaseHandler.handleRequest(request);
    }

    print(
      'Server received request for unsupported application: ${request.header.applicationId}',
    );
    final errorAnswer = DiameterMessage.create(
      request.header.code,
      request.header.applicationId,
      dict,
      flags: DiameterFlags.ERROR,
      hopByHopId: request.header.hopByHopId,
      endToEndId: request.header.endToEndId,
    );
    // DIAMETER_APPLICATION_UNSUPPORTED (3007)
    errorAnswer.addAvp(Avp.create(dict, 268, Unsigned32(3007)));
    return errorAnswer;
  }

  final server = DiameterServer(serverHost, serverPort, dict, serverHandler);
  await server.listen();

  // --- Client Setup ---
  // FIXED: Added the 4th argument 'clientHost' for the IP address.
  final clientBaseHandler = BaseApplicationHandler(
    dict,
    'client.example.com',
    'example.com',
    clientHost,
  );

  final client = DiameterClient(
    serverHost,
    serverPort,
    dict,
    clientBaseHandler.handleRequest,
  );

  await client.connect();

  // Wait a moment for the CER/CEA handshake to complete
  await Future.delayed(Duration(seconds: 2));

  if (client.peer.state == PeerState.open) {
    print("✅ Client connection is OPEN. Ready to send application messages.");
  } else {
    print("❌ Client connection failed to open.");
  }

  print(
    "Example running to demonstrate DWR/DWA heartbeats. Press Ctrl+C to exit.",
  );
  // await ProcessSignal.sigint.first;
  await Future.delayed(Duration(seconds: 5));
  client.disconnect();
  server.close();
  print("Client and server shut down.");
  exit(0);
}
