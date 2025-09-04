// bin/example.dart
import 'package:diameter_rs/diameter_rs.dart';
// import 'package:diameter/protocol/diameter_message.dart';
// import 'package:diameter/dictionary/dictionary.dart';
// import 'package:diameter/applications/base_application.dart';
// import 'package:diameter/transport/server.dart';
// import 'package:diameter/transport/client.dart';
// import 'package:diameter/transport/peer.dart';

void main() async {
  // A minimal dictionary for the base protocol to make this runnable
  final dict = Dictionary.fromListOfAvps([
    AvpDefinition('Origin-Host', 264, AvpType.identity),
    AvpDefinition('Origin-Realm', 296, AvpType.identity),
    AvpDefinition('Host-IP-Address', 257, AvpType.address),
    AvpDefinition('Vendor-Id', 266, AvpType.unsigned32),
    AvpDefinition('Product-Name', 269, AvpType.utf8String),
    AvpDefinition('Result-Code', 268, AvpType.unsigned32),
    AvpDefinition('Auth-Application-Id', 258, AvpType.unsigned32),
    AvpDefinition('Session-Id', 263, AvpType.utf8String),
  ]);

  final serverHost = '127.0.0.1';
  final serverPort = 3868;

  // --- Server Setup ---
  final serverBaseHandler = BaseApplicationHandler(
    dict,
    'server.example.com',
    'example.com',
  );

  RequestHandler serverHandler = (DiameterMessage request) {
    if (request.header.applicationId == ApplicationId.DiameterCommon) {
      return serverBaseHandler.handleRequest(request);
    }
    // else if (request.applicationId == ApplicationId.CreditControl) {
    //   return creditControlHandler.handleRequest(request);
    // }
    throw UnimplementedError(
      'No handler for app id ${request.header.applicationId}',
    );
  };

  final server = DiameterServer(serverHost, serverPort, dict, serverHandler);
  await server.listen();

  // --- Client Setup ---
  final clientBaseHandler = BaseApplicationHandler(
    dict,
    'client.example.com',
    'example.com',
  );
  final client = DiameterClient(
    serverHost,
    serverPort,
    dict,
    clientBaseHandler.handleRequest,
  );

  await client.connect();

  // Wait for the connection to be established
  await Future.delayed(Duration(seconds: 2));

  if (client.peer.state == PeerState.open) {
    print("Client connection is OPEN. Ready to send application messages.");
    // Here you would create and send an application-specific request,
    // for example a Credit-Control-Request.
  } else {
    print("Client connection failed to open.");
  }
}
