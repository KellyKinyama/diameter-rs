// example/server.dart

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:diameter_rs/diameter_rs.dart';
import 'package:diameter_rs/dictionary/default_dictionary_xml.dart'; // <-- FIX: Added this import

// The dictionary needs to be loaded with the 3GPP Ro/Rf definitions.
// Assumes a `dict/3gpp-ro-rf.xml` file exists.
final dict = Dictionary.load([
  defaultDictXml,
  File('dict/3gpp-ro-rf.xml').readAsStringSync(),
]);

/// This is the main request handler for the server.
Future<DiameterMessage> handleRequest(DiameterMessage request) async {
  Logger.root.info("Received request:\n$request");

  // Create a base response message from the request.
  var response = DiameterMessage.create(
    request.header.code,
    request.header.applicationId,
    dict,
    flags:
        request.header.flags & ~DiameterFlags.REQUEST, // Clear the REQUEST bit
    hopByHopId: request.header.hopByHopId,
    endToEndId: request.header.endToEndId,
  );

  // Add AVPs based on the command code.
  switch (request.header.code) {
    case CommandCode.capabilitiesExchange:
      response.addAvp(
        Avp.create(dict, 268, Unsigned32(2001), isMandatory: true),
      ); // Result-Code
      response.addAvp(
        Avp.create(
          dict,
          264,
          Identity("server.example.com"),
          isMandatory: true,
        ),
      ); // Origin-Host
      response.addAvp(
        Avp.create(dict, 296, Identity("realm.example.com"), isMandatory: true),
      ); // Origin-Realm
      response.addAvp(
        Avp.create(dict, 266, Unsigned32(35838), isMandatory: true),
      ); // Vendor-Id
      response.addAvp(
        Avp.create(dict, 269, Utf8String("diameter-dart"), isMandatory: true),
      ); // Product-Name
      response.addAvp(
        Avp.create(dict, 258, Unsigned32(4), isMandatory: true),
      ); // Auth-Application-Id (Credit-Control)
      break;

    case CommandCode.creditControl:
      // Acknowledge the CCR and add some example AVPs.
      response.addAvp(
        Avp.create(dict, 268, Unsigned32(2001), isMandatory: true),
      ); // Result-Code
      response.addAvp(
        Avp.create(
          dict,
          264,
          Identity("server.example.com"),
          isMandatory: true,
        ),
      ); // Origin-Host
      response.addAvp(
        Avp.create(dict, 296, Identity("realm.example.com"), isMandatory: true),
      ); // Origin-Realm

      // Echo the Session-Id from the request
      final sessionIdAvp = request.getAvp(263);
      if (sessionIdAvp != null) {
        response.addAvp(sessionIdAvp);
      }
      break;

    default:
      // For any other command, return DIAMETER_COMMAND_UNSUPPORTED
      response.addAvp(
        Avp.create(dict, 268, Unsigned32(3001), isMandatory: true),
      );
  }

  Logger.root.info("Sending response:\n$response");
  return response;
}

void main() async {
  // Set up a simple logger.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.time}: ${record.level.name}: ${record.message}');
  });

  // Start the server.
  final server = DiameterServer('0.0.0.0', 3868, dict, handleRequest);
  await server.listen();
}
