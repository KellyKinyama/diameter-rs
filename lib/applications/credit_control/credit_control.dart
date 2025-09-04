// lib/applications/credit_control_message.dart

import 'dart:convert';

import 'package:diameter_rs/diameter_rs.dart';

// --- Helper classes for 3GPP Grouped AVPs ---

/// A wrapper for the 3GPP PS-Information AVP (Code 874).
class PsInformation {
  final Grouped _grouped;

  PsInformation(this._grouped);

  /// Creates a new PS-Information object.
  /// `calledStationId` is often used for the APN.
  factory PsInformation.create(Dictionary dict, String calledStationId) {
    final avp = Avp.create(
      dict,
      30,
      Utf8String(calledStationId),
    ); // Called-Station-Id
    return PsInformation(Grouped([avp]));
  }

  /// Gets the Called-Station-Id (APN) from the AVP.
  String? get calledStationId {
    final avp = _grouped.avps.firstWhere(
      (a) => a.header.code == 30,
      orElse: () => Avp.create(
        defaultDictionary,
        0,
        OctetString(utf8.encode('')),
        vendorId: 10415,
      ),
    );
    if (avp.value is Utf8String) {
      return (avp.value as Utf8String).value;
    }
    return null;
  }
}

/// A wrapper for the 3GPP Service-Information AVP (Code 873).
class ServiceInformation {
  final Grouped _grouped;

  ServiceInformation(this._grouped);

  /// Creates a new Service-Information object.
  factory ServiceInformation.create(Dictionary dict, PsInformation psInfo) {
    final avp = Avp.create(
      dict,
      874,
      psInfo._grouped,
      vendorId: 10415,
    ); // PS-Information
    return ServiceInformation(Grouped([avp]));
  }

  /// Gets the PS-Information from the AVP.
  PsInformation? get psInformation {
    final avp = _grouped.avps.firstWhere(
      (a) => a.header.code == 874,
      orElse: () =>
          Avp.create(defaultDictionary, 0, OctetString(utf8.encode(''))),
    );
    if (avp.value is Grouped) {
      return PsInformation(avp.value as Grouped);
    }
    return null;
  }
}

// --- Main Credit-Control-Answer Class ---

/// Represents a Credit-Control-Answer (CCA) message.
class CreditControlAnswer extends DiameterMessage {
  /// Creates a CCA from an existing DiameterMessage.
  /// This is used after decoding a message from the network.
  CreditControlAnswer(DiameterMessage message)
    : super(header: message.header, dict: message.dict, avps: message.avps);

  /// Creates a new CCA as a response to a CCR.
  factory CreditControlAnswer.fromRequest(DiameterMessage ccr) {
    final cca = DiameterMessage.create(
      CommandCode.creditControl,
      ApplicationId.creditControl,
      ccr.dict,
      flags: DiameterFlags.PROXYABLE, // R bit is cleared by default for answers
      hopByHopId: ccr.header.hopByHopId,
      endToEndId: ccr.header.endToEndId,
    );
    // Automatically copy the Session-Id
    final sessionId = ccr.getAvp(263);
    if (sessionId != null) {
      cca.addAvp(sessionId);
    }
    return CreditControlAnswer(cca);
  }

  // --- Getters for easy access to common CCA AVPs ---

  int? get resultCode => (getAvp(268)?.value as Unsigned32?)?.value;
  int? get ccRequestType => (getAvp(416)?.value as Enumerated?)?.value;
  int? get ccRequestNumber => (getAvp(415)?.value as Unsigned32?)?.value;

  ServiceInformation? get serviceInformation {
    final avp = getAvp(873);
    if (avp != null && avp.value is Grouped) {
      return ServiceInformation(avp.value as Grouped);
    }
    return null;
  }

  // --- Setters for easily building a CCA ---

  set resultCode(int? value) {
    if (value == null) return;
    addAvp(Avp.create(dict, 268, Unsigned32(value), isMandatory: true));
  }

  set ccRequestType(int? value) {
    if (value == null) return;
    addAvp(Avp.create(dict, 416, Enumerated(value), isMandatory: true));
  }

  set ccRequestNumber(int? value) {
    if (value == null) return;
    addAvp(Avp.create(dict, 415, Unsigned32(value), isMandatory: true));
  }

  set originHost(String value) {
    addAvp(Avp.create(dict, 264, Identity(value), isMandatory: true));
  }

  set originRealm(String value) {
    addAvp(Avp.create(dict, 296, Identity(value), isMandatory: true));
  }

  set serviceInformation(ServiceInformation? info) {
    if (info == null) return;
    addAvp(
      Avp.create(dict, 873, info._grouped, vendorId: 10415, isMandatory: true),
    );
  }
}
