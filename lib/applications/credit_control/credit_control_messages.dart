// // lib/applications/credit_control_messages.dart

// import 'dart:convert';

// import 'package:diameter_rs/diameter_rs.dart';

// // --- Helper classes for common Grouped AVPs in Credit-Control ---

// /// A wrapper for the Granted-Service-Unit AVP (Code 431).
// class GrantedServiceUnit {
//   final Grouped _grouped;
//   final Dictionary dict;

//   GrantedServiceUnit(this._grouped, this.dict);

//   factory GrantedServiceUnit.create(Dictionary dict, {int? totalOctets}) {
//     final avps = <Avp>[];
//     if (totalOctets != null) {
//       avps.add(
//         Avp.create(dict, 421, Unsigned64(totalOctets)),
//       ); // CC-Total-Octets
//     }
//     // Add other unit types (CC-Time, etc.) here as needed.
//     return GrantedServiceUnit(Grouped(avps), dict);
//   }

//   int? get totalOctets =>
//       (_grouped.avps
//                   .firstWhere(
//                     (a) => a.header.code == 421,
//                     orElse: () => Avp.create(dict, 0, Unsigned64(0)),
//                   )
//                   .value
//               as Unsigned64?)
//           ?.value;
// }

// /// A wrapper for the Multiple-Services-Credit-Control AVP (Code 456).
// class MultipleServicesCreditControl {
//   final Grouped _grouped;
//   final Dictionary dict;

//   MultipleServicesCreditControl(this._grouped, this.dict);

//   factory MultipleServicesCreditControl.create(
//     Dictionary dict, {
//     GrantedServiceUnit? gsu,
//   }) {
//     final avps = <Avp>[];
//     if (gsu != null) {
//       avps.add(Avp.create(dict, 431, gsu._grouped)); // Granted-Service-Unit
//     }
//     return MultipleServicesCreditControl(Grouped(avps), dict);
//   }

//   GrantedServiceUnit? get grantedServiceUnit {
//     final avp = _grouped.avps.firstWhere(
//       (a) => a.header.code == 431,
//       orElse: () => Avp.create(dict, 0, OctetString(utf8.encode(''))),
//     );
//     if (avp.value is Grouped) {
//       return GrantedServiceUnit(avp.value as Grouped, dict);
//     }
//     return null;
//   }
// }

// // --- Main Message Classes ---

// // /// Represents a Credit-Control-Request (CCR) message.
// // class CreditControlRequest extends DiameterMessage {
// //   /// Creates a new CCR from scratch.
// //   CreditControlRequest(Dictionary dict, {String? sessionId})
// //     : super(
// //         header: DiameterHeader(
// //           version: 1,
// //           length: 0, // Will be calculated on encode
// //           flags: DiameterFlags.REQUEST | DiameterFlags.PROXYABLE,
// //           code: CommandCode.creditControl,
// //           applicationId: ApplicationId.creditControl,
// //           hopByHopId: 0, // Will be set by Peer
// //           endToEndId: 0, // Should be set by caller
// //         ),
// //         dict: dict,
// //       ) {
// //     this.sessionId =
// //         sessionId ??
// //         'default-session-id;${DateTime.now().millisecondsSinceEpoch}';
// //   }

// //   // --- Getters and Setters for convenient AVP access ---

// //   String get sessionId => (getAvp(263)!.value as Utf8String).value;
// //   set sessionId(String value) {
// //     // Remove old one if it exists, then add new one
// //     avps.removeWhere((avp) => avp.header.code == 263);
// //     addAvp(Avp.create(dict, 263, Utf8String(value), isMandatory: true));
// //   }

// //   String get originHost => (getAvp(264)!.value as Utf8String).value;
// //   set originHost(String value) {
// //     avps.removeWhere((avp) => avp.header.code == 264);
// //     addAvp(Avp.create(dict, 264, Identity(value), isMandatory: true));
// //   }

// //   // Add other getters/setters for CCR AVPs as needed, following the pattern above.
// //   // E.g., for CC-Request-Type, User-Name, etc.
// // }

// /// Represents a Credit-Control-Answer (CCA) message.
// class CreditControlAnswer extends DiameterMessage {
//   /// Creates a CCA by wrapping a decoded DiameterMessage.
//   CreditControlAnswer(DiameterMessage message)
//     : super(header: message.header, dict: message.dict, avps: message.avps);

//   /// Creates a new CCA as a response to a CCR.
//   factory CreditControlAnswer.fromRequest(DiameterMessage ccr) {
//     final cca = DiameterMessage.create(
//       CommandCode.creditControl,
//       ApplicationId.creditControl,
//       ccr.dict,
//       flags: DiameterFlags.PROXYABLE,
//       hopByHopId: ccr.header.hopByHopId,
//       endToEndId: ccr.header.endToEndId,
//     );
//     final sessionId = ccr.getAvp(263);
//     if (sessionId != null) {
//       cca.addAvp(sessionId);
//     }
//     return CreditControlAnswer(cca);
//   }

//   // --- Getters for easy access to common CCA AVPs ---

//   int? get resultCode => (getAvp(268)?.value as Unsigned32?)?.value;
//   int? get ccRequestType => (getAvp(416)?.value as Enumerated?)?.value;
//   int? get ccRequestNumber => (getAvp(415)?.value as Unsigned32?)?.value;

//   List<MultipleServicesCreditControl> get multipleServicesCreditControl {
//     return avps
//         .where((avp) => avp.header.code == 456)
//         .map((avp) => MultipleServicesCreditControl(avp.value as Grouped, dict))
//         .toList();
//   }

//   // Add other getters as needed.
// }

// class PsInformation {
//   final Grouped _grouped;

//   PsInformation(this._grouped);

//   /// Creates a new PS-Information object.
//   /// `calledStationId` is often used for the APN.
//   factory PsInformation.create(Dictionary dict, String calledStationId) {
//     final avp = Avp.create(
//       dict,
//       30,
//       Utf8String(calledStationId),
//     ); // Called-Station-Id
//     return PsInformation(Grouped([avp]));
//   }

//   /// Gets the Called-Station-Id (APN) from the AVP.
//   String? get calledStationId {
//     final avp = _grouped.avps.firstWhere(
//       (a) => a.header.code == 30,
//       orElse: () => Avp.create(
//         defaultDictionary,
//         0,
//         OctetString(utf8.encode('')),
//         vendorId: 10415,
//       ),
//     );
//     if (avp.value is Utf8String) {
//       return (avp.value as Utf8String).value;
//     }
//     return null;
//   }
// }

// /// A wrapper for the 3GPP Service-Generic-Information AVP (Code 1250).
// class ServiceGenericInformation {
//   final Grouped _grouped;
//   final Dictionary dict;

//   ServiceGenericInformation(this._grouped, this.dict);

//   factory ServiceGenericInformation.create(
//     Dictionary dict, {
//     int? applicationServerId,
//     int? applicationServiceType,
//     int? applicationSessionId,
//     String? deliveryStatus,
//   }) {
//     final avps = <Avp>[];
//     if (applicationServerId != null) {
//       avps.add(
//         Avp.create(dict, 1251, Integer32(applicationServerId), vendorId: 10415),
//       );
//     }
//     if (applicationServiceType != null) {
//       avps.add(
//         Avp.create(
//           dict,
//           1252,
//           Enumerated(applicationServiceType),
//           vendorId: 10415,
//         ),
//       );
//     }
//     if (applicationSessionId != null) {
//       avps.add(
//         Avp.create(
//           dict,
//           1253,
//           Unsigned32(applicationSessionId),
//           vendorId: 10415,
//         ),
//       );
//     }
//     if (deliveryStatus != null) {
//       avps.add(
//         Avp.create(dict, 1254, Utf8String(deliveryStatus), vendorId: 10415),
//       );
//     }
//     return ServiceGenericInformation(Grouped(avps), dict);
//   }
// }

// /// A wrapper for the 3GPP Service-Information AVP (Code 873).
// class ServiceInformation {
//   final Grouped _grouped;
//   final Dictionary dict;

//   ServiceInformation(this._grouped, this.dict);

//   factory ServiceInformation.create(
//     Dictionary dict, {
//     PsInformation? psInformation,
//     ServiceGenericInformation? serviceGenericInformation,
//   }) {
//     final avps = <Avp>[];
//     if (psInformation != null) {
//       avps.add(Avp.create(dict, 874, psInformation._grouped, vendorId: 10415));
//     }
//     if (serviceGenericInformation != null) {
//       avps.add(
//         Avp.create(
//           dict,
//           1250,
//           serviceGenericInformation._grouped,
//           vendorId: 10415,
//         ),
//       );
//     }
//     return ServiceInformation(Grouped(avps), dict);
//   }
// }

// // ... (Other helper classes like PsInformation, GrantedServiceUnit remain the same) ...

// /// Represents a Credit-Control-Request (CCR) message.
// class CreditControlRequest extends DiameterMessage {
//   CreditControlRequest(Dictionary dict)
//     : super.create(
//         CommandCode.creditControl,
//         ApplicationId.creditControl,
//         dict,
//         flags: DiameterFlags.REQUEST | DiameterFlags.PROXYABLE,
//       );

//   // --- Setters for convenient AVP access, mirroring the Python example ---

//   set sessionId(String value) => _setAvp(263, Utf8String(value));
//   set originHost(String value) => _setAvp(264, Identity(value));
//   set originRealm(String value) => _setAvp(296, Identity(value));
//   set destinationRealm(String value) => _setAvp(283, Identity(value));
//   set serviceContextId(String value) => _setAvp(461, Utf8String(value));
//   set ccRequestType(int value) => _setAvp(416, Enumerated(value));
//   set ccRequestNumber(int value) => _setAvp(415, Unsigned32(value));

//   set serviceInformation(ServiceInformation? info) {
//     if (info == null) return;
//     _setAvp(873, info._grouped, vendorId: 10415);
//   }

//   // Helper to avoid duplicate AVPs
//   void _setAvp(int code, AvpValue value, {int? vendorId}) {
//     avps.removeWhere(
//       (avp) => avp.header.code == code && avp.header.vendorId == vendorId,
//     );
//     addAvp(
//       Avp.create(dict, code, value, vendorId: vendorId, isMandatory: true),
//     );
//   }
// }

// /// A wrapper for the 3GPP Service-Information AVP (Code 873).
// // class ServiceInformation {
// //   final Grouped _grouped;

// //   ServiceInformation(this._grouped);

// //   /// Creates a new Service-Information object.
// //   factory ServiceInformation.create(Dictionary dict, PsInformation psInfo) {
// //     final avp = Avp.create(
// //       dict,
// //       874,
// //       psInfo._grouped,
// //       vendorId: 10415,
// //     ); // PS-Information
// //     return ServiceInformation(Grouped([avp]));
// //   }

//   /// Gets the PS-Information from the AVP.
// //   PsInformation? get psInformation {
// //     final avp = _grouped.avps.firstWhere(
// //       (a) => a.header.code == 874,
// //       orElse: () =>
// //           Avp.create(defaultDictionary, 0, OctetString(utf8.encode(''))),
// //     );
// //     if (avp.value is Grouped) {
// //       return PsInformation(avp.value as Grouped);
// //     }
// //     return null;
// //   }
// // }

// lib/applications/credit_control_messages.dart

import 'dart:math';

import 'package:diameter_rs/diameter_rs.dart';

// --- Helper classes for common Grouped AVPs in Credit-Control ---
// (These remain the same as the previous version)

/// A wrapper for the Granted-Service-Unit AVP (Code 431).
class GrantedServiceUnit {
  final Grouped _grouped;
  final Dictionary dict;

  GrantedServiceUnit(this._grouped, this.dict);

  factory GrantedServiceUnit.create(Dictionary dict, {int? totalOctets}) {
    final avps = <Avp>[];
    if (totalOctets != null) {
      avps.add(
        Avp.create(dict, 421, Unsigned64(totalOctets)),
      ); // CC-Total-Octets
    }
    return GrantedServiceUnit(Grouped(avps), dict);
  }

  int? get totalOctets =>
      (_grouped.avps
                  .firstWhere(
                    (a) => a.header.code == 421,
                    orElse: () => Avp.create(dict, 0, Unsigned64(0)),
                  )
                  .value
              as Unsigned64?)
          ?.value;
}

/// A wrapper for the 3GPP Service-Information AVP (Code 873).
class ServiceInformation {
  final Grouped _grouped;
  final Dictionary dict;

  ServiceInformation(this._grouped, this.dict);

  factory ServiceInformation.create(
    Dictionary dict, {
    ServiceGenericInformation? serviceGenericInformation,
  }) {
    final avps = <Avp>[];
    if (serviceGenericInformation != null) {
      avps.add(
        Avp.create(
          dict,
          1250,
          serviceGenericInformation._grouped,
          vendorId: 10415,
        ),
      );
    }
    return ServiceInformation(Grouped(avps), dict);
  }
}

/// A wrapper for the 3GPP Service-Generic-Information AVP (Code 1250).
class ServiceGenericInformation {
  final Grouped _grouped;
  final Dictionary dict;

  ServiceGenericInformation(this._grouped, this.dict);

  factory ServiceGenericInformation.create(
    Dictionary dict, {
    int? applicationServerId,
    int? applicationServiceType,
    int? applicationSessionId,
    String? deliveryStatus,
  }) {
    final avps = <Avp>[];
    if (applicationServerId != null) {
      avps.add(
        Avp.create(dict, 1251, Integer32(applicationServerId), vendorId: 10415),
      );
    }
    if (applicationServiceType != null) {
      avps.add(
        Avp.create(
          dict,
          1252,
          Enumerated(applicationServiceType),
          vendorId: 10415,
        ),
      );
    }
    if (applicationSessionId != null) {
      avps.add(
        Avp.create(
          dict,
          1253,
          Unsigned32(applicationSessionId),
          vendorId: 10415,
        ),
      );
    }
    if (deliveryStatus != null) {
      avps.add(
        Avp.create(dict, 1254, Utf8String(deliveryStatus), vendorId: 10415),
      );
    }
    return ServiceGenericInformation(Grouped(avps), dict);
  }
}

// --- Main Message Classes ---

/// Represents a Credit-Control-Request (CCR) message.
class CreditControlRequest extends DiameterMessage {
  /// Creates a new CCR from scratch.
  CreditControlRequest(Dictionary dict)
    // FIXED: Call the main generative `super` constructor by building the header first.
    : super(
        header: DiameterHeader(
          version: 1,
          length: 0, // Will be calculated on encode
          flags: DiameterFlags.REQUEST | DiameterFlags.PROXYABLE,
          code: CommandCode.creditControl,
          applicationId: ApplicationId.creditControl,
          hopByHopId: 0, // Will be set by Peer transport
          endToEndId: Random().nextInt(0xFFFFFFFF), // Should be unique
        ),
        dict: dict,
      );

  // --- Getters and Setters for convenient AVP access ---

  String? get sessionId => (getAvp(263)?.value as Utf8String?)?.value;
  set sessionId(String? value) => _setAvp(263, Utf8String(value!));

  String? get originHost => (getAvp(264)?.value as Utf8String?)?.value;
  set originHost(String? value) => _setAvp(264, Identity(value!));

  String? get originRealm => (getAvp(296)?.value as Utf8String?)?.value;
  set originRealm(String? value) => _setAvp(296, Identity(value!));

  String? get destinationRealm => (getAvp(283)?.value as Utf8String?)?.value;
  set destinationRealm(String? value) => _setAvp(283, Identity(value!));

  String? get serviceContextId => (getAvp(461)?.value as Utf8String?)?.value;
  set serviceContextId(String? value) => _setAvp(461, Utf8String(value!));

  int? get ccRequestType => (getAvp(416)?.value as Enumerated?)?.value;
  set ccRequestType(int? value) => _setAvp(416, Enumerated(value!));

  int? get ccRequestNumber => (getAvp(415)?.value as Unsigned32?)?.value;
  set ccRequestNumber(int? value) => _setAvp(415, Unsigned32(value!));

  set serviceInformation(ServiceInformation? info) {
    if (info == null) return;
    _setAvp(873, info._grouped, vendorId: 10415);
  }

  // Helper to add/replace an AVP
  void _setAvp(int code, AvpValue value, {int? vendorId}) {
    avps.removeWhere(
      (avp) => avp.header.code == code && avp.header.vendorId == vendorId,
    );
    addAvp(
      Avp.create(dict, code, value, vendorId: vendorId, isMandatory: true),
    );
  }
}

/// Represents a Credit-Control-Answer (CCA) message.
class CreditControlAnswer extends DiameterMessage {
  /// Creates a CCA by wrapping a decoded DiameterMessage.
  CreditControlAnswer(DiameterMessage message)
    : super(header: message.header, dict: message.dict, avps: message.avps);
}
