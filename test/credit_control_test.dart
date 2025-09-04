// test/credit_control_test.dart

import 'package:test/test.dart';
import 'package:diameter_rs/diameter_rs.dart';
// import 'package:diameter_rs/applications/credit_control_messages.dart';

// Service Context ID constant for 3GPP PS Charging
const serviceContextPsCharging = "32251@3gpp.org";

// CC-Request-Type constant for UPDATE_REQUEST
const ccRequestTypeUpdate = 2;

void main() {
  group('CreditControlRequest', () {
    final dict = defaultDictionary;

    test(
      'Correctly builds and encodes a CCR with 3GPP Service-Generic-Information',
      () {
        // 1. Create the high-level CCR message object
        final ccr = CreditControlRequest(dict);

        // 2. Set properties, mirroring the Python test
        ccr.sessionId =
            "sctp-saegwc-poz01.lte.orange.pl;221424325;287370797;65574b0c-2d02";
        ccr.originHost = "dra2.gy.mno.net";
        ccr.originRealm = "mno.net";
        ccr.destinationRealm = "mvno.net";
        ccr.serviceContextId = serviceContextPsCharging;
        ccr.ccRequestType = ccRequestTypeUpdate;
        ccr.ccRequestNumber = 952;

        // 3. Populate the nested grouped AVPs
        final genericInfo = ServiceGenericInformation.create(
          dict,
          applicationServerId: 1,
          applicationServiceType: 1, // Corresponds to RECEIVING
          applicationSessionId: 5,
          deliveryStatus: "delivered",
        );

        ccr.serviceInformation = ServiceInformation.create(
          dict,
          serviceGenericInformation: genericInfo,
        );

        // 4. Encode the message to bytes
        final encodedBytes = ccr.encode();

        // 5. Assert that the length in the header matches the actual byte length
        expect(ccr.header.length, encodedBytes.length);
        print(
          "Encoded CCR with 3GPP extensions successfully. Length: ${encodedBytes.length} bytes.",
        );

        // 6. (Optional but recommended) Decode and verify the content
        final decodedMessage = DiameterMessage.decode(encodedBytes, dict);
        final decodedCcr = CreditControlRequest(decodedMessage.dict);
        decodedCcr.avps = decodedMessage.avps;

        expect(decodedCcr.sessionId, ccr.sessionId);
        expect(decodedCcr.ccRequestNumber, 952);

        // Verify nested AVP
        final decodedServiceInfo = decodedMessage.getAvp(873);
        expect(decodedServiceInfo, isNotNull);
        expect(decodedServiceInfo!.value, isA<Grouped>());

        final genericInfoGroup = (decodedServiceInfo.value as Grouped).avps
            .firstWhere((avp) => avp.header.code == 1250);
        expect(genericInfoGroup, isNotNull);
      },
    );
  });
}
