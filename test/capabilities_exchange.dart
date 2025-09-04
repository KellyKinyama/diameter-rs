// test/base_protocol_test.dart

import 'dart:io';

import 'package:test/test.dart';
import 'package:diameter_rs/diameter_rs.dart';

void main() {
  group('Capabilities-Exchange', () {
    final dict = defaultDictionary;

    test('CER: correctly builds and encodes a full request', () {
      // 1. Build a CER with every attribute populated.
      final cer = CapabilitiesExchangeRequest(dict);
      cer.originHost = "dra2.gy.mno.net";
      cer.originRealm = "mno.net";
      cer.hostIpAddress = ["10.12.56.109"];
      cer.vendorId = 99999;
      cer.productName = "dart-diameter-stack";
      cer.originStateId = 1689134718;
      cer.supportedVendorId = [10415]; // 3GPP
      cer.authApplicationId = [ApplicationId.creditControl.id];
      cer.acctApplicationId = [ApplicationId.creditControl.id];
      cer.inbandSecurityId = [0]; // NO_INBAND_SECURITY
      cer.firmwareRevision = 16777216;

      // 2. Encode the message to bytes.
      final msg = cer.encode();

      // 3. Perform assertions, mirroring the Python test.
      expect(cer.header.length, msg.length);
      expect((cer.header.flags & DiameterFlags.REQUEST) != 0, isTrue);

      // 4. Decode and verify content.
      final decodedCer = CapabilitiesExchangeRequest.fromMessage(
        DiameterMessage.decode(msg, dict),
      );
      expect(
        decodedCer.authApplicationId.first,
        ApplicationId.creditControl.id,
      );
      expect(decodedCer.originHost, "dra2.gy.mno.net");
    });

    test('CEA: correctly builds and encodes a full answer', () {
      // 1. Build a CEA with every attribute populated.
      // We need a dummy request to create an answer from.
      final dummyCer = CapabilitiesExchangeRequest(dict);
      final cea = CapabilitiesExchangeAnswer.fromRequest(dummyCer);

      cea.resultCode = 5012; // DIAMETER_UNABLE_TO_COMPLY
      cea.originHost = "dra1.mvno.net";
      cea.originRealm = "mvno.net";
      cea.hostIpAddress = ["10.16.36.201"];
      cea.vendorId = 39216;
      cea.productName = "Dart-BFX";
      cea.originStateId = 1689134718;
      cea.errorMessage = "Invalid state to receive a new connection attempt.";
      cea.failedAvp = FailedAvp.create(dict, [
        Avp.create(
          dict,
          257,
          Address(AddressIPv4Value(InternetAddress("10.12.56.109"))),
        ), // Host-IP-Address
      ]);
      cea.supportedVendorId = [9, 10415, 13019];
      cea.authApplicationId = [ApplicationId.creditControl.id];
      cea.firmwareRevision = 300;

      // 2. Encode the message.
      final msg = cea.encode();

      // 3. Perform assertions.
      expect(cea.header.length, msg.length);
      expect((cea.header.flags & DiameterFlags.REQUEST) == 0, isTrue);

      // 4. Decode and verify content.
      final decodedCea = CapabilitiesExchangeAnswer.fromMessage(
        DiameterMessage.decode(msg, dict),
      );
      expect(
        decodedCea.authApplicationId.first,
        ApplicationId.creditControl.id,
      );
      expect(decodedCea.resultCode, 5012);
      expect(decodedCea.failedAvp?.containedAvps.first.header.code, 257);
    });

    test('Can create a valid CEA from a CER', () {
      final req = CapabilitiesExchangeRequest(dict);
      // Use the convenience method
      final ans = req.toAnswer();

      expect(ans, isA<CapabilitiesExchangeAnswer>());
      expect((ans.header.flags & DiameterFlags.REQUEST) == 0, isTrue);
      expect(ans.header.hopByHopId, req.header.hopByHopId);
      expect(ans.header.endToEndId, req.header.endToEndId);
    });
  });
}
