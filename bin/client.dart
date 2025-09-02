// example/client.dart

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:diameter_rs/diameter_rs.dart';
import 'package:diameter_rs/dictionary/default_dictionary_xml.dart'; // <-- FIX: Added this import

final dict = Dictionary.load([
  defaultDictXml,
  File('dict/3gpp-ro-rf.xml').readAsStringSync(),
]);

Future<void> sendCer(DiameterClient client) async {
  var cer = DiameterMessage.create(
    CommandCode.capabilitiesExchange,
    ApplicationId.common,
    dict,
    flags: DiameterFlags.REQUEST,
  );

  cer.addAvp(
    Avp.create(dict, 264, Identity("client.example.com"), isMandatory: true),
  );
  cer.addAvp(
    Avp.create(dict, 296, Identity("realm.example.com"), isMandatory: true),
  );
  final hostIpAddress = Address(AddressIPv4Value(InternetAddress("127.0.0.1")));
  cer.addAvp(Avp.create(dict, 257, hostIpAddress, isMandatory: true));
  cer.addAvp(Avp.create(dict, 266, Unsigned32(35838), isMandatory: true));
  cer.addAvp(
    Avp.create(dict, 269, Utf8String("diameter-dart"), isMandatory: true),
  );

  Logger.root.info("Sending CER...");
  final cea = await client.sendRequest(cer);
  Logger.root.info("Received CEA:\n$cea");
}

Future<void> sendCcr(DiameterClient client) async {
  var ccr = DiameterMessage.create(
    CommandCode.creditControl,
    ApplicationId.creditControl,
    dict,
    flags: DiameterFlags.REQUEST,
  );

  ccr.addAvp(
    Avp.create(dict, 263, Utf8String("ses;12345888"), isMandatory: true),
  ); // Session-Id
  ccr.addAvp(
    Avp.create(dict, 264, Identity("client.example.com"), isMandatory: true),
  ); // Origin-Host
  ccr.addAvp(
    Avp.create(dict, 296, Identity("realm.example.com"), isMandatory: true),
  ); // Origin-Realm
  ccr.addAvp(
    Avp.create(dict, 416, Enumerated(1), isMandatory: true),
  ); // CC-Request-Type (INITIAL)
  ccr.addAvp(
    Avp.create(dict, 415, Unsigned32(0), isMandatory: true),
  ); // CC-Request-Number

  Logger.root.info("Sending CCR...");
  final cca = await client.sendRequest(ccr);
  Logger.root.info("Received CCA:\n$cca");
}

void main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.time}: ${record.level.name}: ${record.message}');
  });

  final client = DiameterClient('localhost', 3868, dict);

  try {
    await client.connect();
    Logger.root.info("Client connected.");

    await sendCer(client);
    await sendCcr(client);
  } catch (e) {
    Logger.root.severe("An error occurred: $e");
  } finally {
    client.disconnect();
    Logger.root.info("Client disconnected.");
  }
}
