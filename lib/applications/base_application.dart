// lib/applications/base_application.dart

import 'dart:io';

import '../diameter_rs.dart';
// import '../dictionary/dictionary.dart';
// import '../avp/avp.dart';
// import '../avp/unsigned32.dart';
// import '../avp/identity.dart';
// import '../avp/utf8string.dart';
// import '../avp/address.dart';
// import '../avp/ipv4.dart';

class BaseApplicationHandler {
  final Dictionary dict;
  final String originHost;
  final String originRealm;
  final String ipAddress;

  BaseApplicationHandler(
    this.dict,
    this.originHost,
    this.originRealm,
    this.ipAddress,
  );

  /// FIXED: This method is now synchronous.
  DiameterMessage handleRequest(DiameterMessage request) {
    switch (request.header.code) {
      case CommandCode.capabilitiesExchange:
        return handleCER(request);
      case CommandCode.deviceWatchdog:
        return handleDWR(request);
      default:
        throw UnimplementedError('Command not supported by base handler');
    }
  }

  /// FIXED: This method is now synchronous.
  DiameterMessage handleCER(DiameterMessage cer) {
    print("Handling CER from ${cer.getAvp(AvpCode.OriginHost)?.value}");

    final cea = DiameterMessage.create(
      CommandCode.capabilitiesExchange,
      ApplicationId.common,
      dict,
      hopByHopId: cer.header.hopByHopId,
      endToEndId: cer.header.endToEndId,
    );

    cea.addAvp(
      Avp.create(
        dict,
        AvpCode.ResultCode,
        Unsigned32(ResultCode.DIAMETER_SUCCESS),
      ),
    );
    cea.addAvp(Avp.create(dict, AvpCode.OriginHost, Identity(originHost)));
    cea.addAvp(Avp.create(dict, AvpCode.OriginRealm, Identity(originRealm)));
    cea.addAvp(
      Avp.create(
        dict,
        AvpCode.HostIpAddress,
        Address(AddressIPv4Value(InternetAddress(ipAddress))),
      ),
    );
    cea.addAvp(Avp.create(dict, AvpCode.VendorId, Unsigned32(0)));
    cea.addAvp(
      Avp.create(dict, AvpCode.ProductName, Utf8String("Dart Diameter")),
    );
    cea.addAvp(
      Avp.create(
        dict,
        AvpCode.AuthApplicationId,
        Unsigned32(ApplicationId.creditControl.id),
      ),
    );

    return cea;
  }

  /// FIXED: This method is now synchronous.
  DiameterMessage handleDWR(DiameterMessage dwr) {
    final dwa = DiameterMessage.create(
      CommandCode.deviceWatchdog,
      ApplicationId.common,
      dict,
      hopByHopId: dwr.header.hopByHopId,
      endToEndId: dwr.header.endToEndId,
    );

    dwa.addAvp(
      Avp.create(
        dict,
        AvpCode.ResultCode,
        Unsigned32(ResultCode.DIAMETER_SUCCESS),
      ),
    );
    dwa.addAvp(Avp.create(dict, AvpCode.OriginHost, Identity(originHost)));
    dwa.addAvp(Avp.create(dict, AvpCode.OriginRealm, Identity(originRealm)));

    return dwa;
  }
}
