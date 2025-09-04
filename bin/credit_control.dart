// bin/example.dart
import 'dart:io';

import 'package:diameter_rs/diameter_rs.dart';
import 'package:diameter_rs/applications/base_application.dart';
// Import the new message classes
import 'package:diameter_rs/applications/credit_control_messages.dart';
import 'package:diameter_rs/dictionary/default_dictionary_xml.dart';

void main() async {
  final dict = Dictionary.load([defaultDictXml]);
  final serverHost = '127.0.0.1';
  final serverPort = 3868;

  // --- Server Setup ---
  final serverBaseHandler =
      BaseApplicationHandler(dict, 'server.example.com', 'example.com', serverHost);
  
  // A simple handler for Credit-Control requests
  DiameterMessage creditControlHandler(DiameterMessage request) {
    final ccr = CreditControlRequest(request.dict); // Not really a request, just a wrapper for easier access
    ccr.avps = request.avps; // Not ideal, but demonstrates the idea
    print("Server received CCR for Session-ID: ${ccr.sessionId}");

    // Build a response using the new classes
    final cca = CreditControlAnswer.fromRequest(request);
    cca.resultCode = 2001; // SUCCESS
    cca.originHost = 'server.example.com';
    cca.originRealm = 'example.com';
    
    final ccRequestType = request.getAvp(416);
    if (ccRequestType != null) cca.addAvp(ccRequestType);

    final ccRequestNumber = request.getAvp(415);
    if (ccRequestNumber != null) cca.addAvp(ccRequestNumber);
    
    // Add a GSU using the convenience wrapper
    final gsu = GrantedServiceUnit.create(dict, totalOctets: 1048576); // Grant 1MB
    final mscc = MultipleServicesCreditControl.create(dict, gsu: gsu);
    cca.addAvp(Avp.create(dict, 456, mscc._grouped)); // Add the MSCC AVP
    
    return cca;
  }

  DiameterMessage serverHandler(DiameterMessage request) {
    if (request.header.applicationId == ApplicationId.DiameterCommon) {
      return serverBaseHandler.handleRequest(request);
    } else if (request.header.applicationId == ApplicationId.creditControl) {
      return creditControlHandler(request);
    }
    // ... error handling
    throw UnimplementedError();
  }

  final server = DiameterServer(serverHost, serverPort, dict, serverHandler);
  await server.listen();

  // --- Client Setup ---
  final clientBaseHandler =
      BaseApplicationHandler(dict, 'client.example.com', 'example.com', serverHost);
  final client = DiameterClient(
    host: serverHost, port: serverPort, dict: dict, handler: clientBaseHandler.handleRequest,
    originHost: 'client.example.com', originRealm: 'example.com', ipAddress: serverHost,
  );

  await client.connect();
  await Future.delayed(Duration(seconds: 1));

  if (client.peer.state == PeerState.open) {
    print("✅ Client connection is OPEN. Sending a Credit-Control-Request.");
    
    // --- Create and send a CCR using the new class ---
    final ccr = CreditControlRequest(dict);
    ccr.originHost = "client.example.com";
    ccr.addAvp(Avp.create(dict, 296, Identity("example.com")));
    ccr.addAvp(Avp.create(dict, 283, Identity("example.com")));
    ccr.addAvp(Avp.create(dict, 258, Unsigned32(4)));
    ccr.addAvp(Avp.create(dict, 416, Enumerated(1))); // INITIAL_REQUEST
    ccr.addAvp(Avp.create(dict, 415, Unsigned32(0)));
    ccr.addAvp(Avp.create(dict, 1, Utf8String("user@example.com")));
    ccr.addAvp(Avp.create(dict, 461, Utf8String("example-service@example.com")));
    
    final response = await client.sendRequest(ccr);
    
    // Wrap the generic response in our specific class for easy parsing
    final cca = CreditControlAnswer(response);

    print("✅ Received CCA response!");
    print("   Result-Code: ${cca.resultCode}");

    // Easily access nested information
    final grantedOctets = cca.multipleServicesCreditControl.first
      .grantedServiceUnit?.totalOctets;
    print("   Granted Octets: $grantedOctets");

  } else {
    print("❌ Client connection failed to open.");
  }

  await Future.delayed(Duration(seconds: 1));
  client.disconnect();
  server.close();
  print("Client and server shut down.");
  exit(0);
}