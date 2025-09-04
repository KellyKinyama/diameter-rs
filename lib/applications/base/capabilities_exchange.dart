// lib/applications/base_messages.dart

import 'dart:io';
import 'dart:math';
import 'package:diameter_rs/diameter_rs.dart';

// A wrapper for the Failed-AVP (Code 279), which is a Grouped AVP.
class FailedAvp {
  final Grouped _grouped;
  final Dictionary dict;

  FailedAvp(this._grouped, this.dict);

  /// Creates a new FailedAvp containing the AVPs that caused an error.
  factory FailedAvp.create(Dictionary dict, List<Avp> failedAvps) {
    return FailedAvp(Grouped(failedAvps), dict);
  }

  /// Returns the list of AVPs that are contained within this FailedAvp.
  List<Avp> get containedAvps => _grouped.avps;
}

/// Represents a Capabilities-Exchange-Request (CER) message.
class CapabilitiesExchangeRequest extends DiameterMessage {
  /// Creates a new CER from scratch.
  CapabilitiesExchangeRequest(Dictionary dict)
    : super(
        header: DiameterHeader(
          version: 1,
          length: 0,
          flags: DiameterFlags.REQUEST,
          code: CommandCode.capabilitiesExchange,
          applicationId: ApplicationId.common,
          hopByHopId: 0,
          endToEndId: Random().nextInt(0xFFFFFFFF),
        ),
        dict: dict,
      );

  /// FIXED: Creates a CER by wrapping a decoded DiameterMessage.
  CapabilitiesExchangeRequest.fromMessage(DiameterMessage message)
    : super(header: message.header, dict: message.dict, avps: message.avps);

  // --- Getters for parsing a received CER ---

  String? get originHost => (getAvp(264)?.value as Utf8String?)?.value;
  String? get originRealm => (getAvp(296)?.value as Utf8String?)?.value;
  List<String> get hostIpAddress =>
      _getList(257).map((v) => v.toString()).toList();
  List<int> get authApplicationId =>
      _getList(258).map((v) => (v as Unsigned32).value).toList();

  // --- Setters for easily building a CER, mirroring the Python API ---

  set originHost(String value) => _setAvp(264, Identity(value));
  set originRealm(String value) => _setAvp(296, Identity(value));
  set hostIpAddress(List<String> addresses) {
    _removeAvp(257);
    for (var addr in addresses) {
      addAvp(
        Avp.create(
          dict,
          257,
          Address(AddressIPv4Value(InternetAddress(addr))),
          isMandatory: true,
        ),
      );
    }
  }

  set vendorId(int value) => _setAvp(266, Unsigned32(value));
  set productName(String value) => _setAvp(269, Utf8String(value));
  set originStateId(int value) => _setAvp(278, Unsigned32(value));
  set firmwareRevision(int value) => _setAvp(267, Unsigned32(value));

  set supportedVendorId(List<int> ids) {
    _removeAvp(265);
    for (var id in ids) {
      addAvp(Avp.create(dict, 265, Unsigned32(id), isMandatory: true));
    }
  }

  set authApplicationId(List<int> ids) {
    _removeAvp(258);
    for (var id in ids) {
      addAvp(Avp.create(dict, 258, Unsigned32(id), isMandatory: true));
    }
  }

  set acctApplicationId(List<int> ids) {
    _removeAvp(259);
    for (var id in ids) {
      addAvp(Avp.create(dict, 259, Unsigned32(id), isMandatory: true));
    }
  }

  set inbandSecurityId(List<int> ids) {
    _removeAvp(299);
    for (var id in ids) {
      addAvp(Avp.create(dict, 299, Unsigned32(id), isMandatory: true));
    }
  }

  void _setAvp(int code, AvpValue value) {
    _removeAvp(code);
    addAvp(Avp.create(dict, code, value, isMandatory: true));
  }

  void _removeAvp(int code) =>
      avps.removeWhere((avp) => avp.header.code == code);
  List<AvpValue> _getList(int code) =>
      avps.where((a) => a.header.code == code).map((a) => a.value).toList();

  /// Convenience method to create an answer from this request.
  CapabilitiesExchangeAnswer toAnswer() {
    return CapabilitiesExchangeAnswer.fromRequest(this);
  }
}

/// Represents a Capabilities-Exchange-Answer (CEA) message.
class CapabilitiesExchangeAnswer extends DiameterMessage {
  CapabilitiesExchangeAnswer.fromMessage(DiameterMessage message)
    : super(header: message.header, dict: message.dict, avps: message.avps);

  factory CapabilitiesExchangeAnswer.fromRequest(DiameterMessage cer) {
    final cea = DiameterMessage.create(
      CommandCode.capabilitiesExchange,
      ApplicationId.common,
      cer.dict,
      flags: 0,
      hopByHopId: cer.header.hopByHopId,
      endToEndId: cer.header.endToEndId,
    );
    return CapabilitiesExchangeAnswer.fromMessage(cea);
  }

  // --- Getters and Setters for CEA ---

  int? get resultCode => (getAvp(268)?.value as Unsigned32?)?.value;
  set resultCode(int? value) => _setAvp(268, Unsigned32(value!));

  String? get originHost => (getAvp(264)?.value as Utf8String?)?.value;
  set originHost(String? value) => _setAvp(264, Identity(value!));

  String? get originRealm => (getAvp(296)?.value as Utf8String?)?.value;
  set originRealm(String? value) => _setAvp(296, Identity(value!));

  List<String> get hostIpAddress =>
      _getList(257).map((v) => v.toString()).toList();
  set hostIpAddress(List<String> addresses) {
    _removeAvp(257);
    for (var addr in addresses) {
      addAvp(
        Avp.create(
          dict,
          257,
          Address(AddressIPv4Value(InternetAddress(addr))),
          isMandatory: true,
        ),
      );
    }
  }

  int? get vendorId => (getAvp(266)?.value as Unsigned32?)?.value;
  set vendorId(int? value) => _setAvp(266, Unsigned32(value!));

  String? get productName => (getAvp(269)?.value as Utf8String?)?.value;
  set productName(String? value) => _setAvp(269, Utf8String(value!));

  int? get originStateId => (getAvp(278)?.value as Unsigned32?)?.value;
  set originStateId(int? value) => _setAvp(278, Unsigned32(value!));

  int? get firmwareRevision => (getAvp(267)?.value as Unsigned32?)?.value;
  set firmwareRevision(int? value) => _setAvp(267, Unsigned32(value!));

  String? get errorMessage => (getAvp(281)?.value as Utf8String?)?.value;
  set errorMessage(String? value) => _setAvp(281, Utf8String(value!));

  FailedAvp? get failedAvp {
    final avp = getAvp(279);
    return (avp != null) ? FailedAvp(avp.value as Grouped, dict) : null;
  }

  set failedAvp(FailedAvp? value) {
    if (value == null) return;
    _setAvp(279, value._grouped);
  }

  List<int> get supportedVendorId =>
      _getList(265).map((v) => (v as Unsigned32).value).toList();
  set supportedVendorId(List<int> ids) {
    _removeAvp(265);
    for (var id in ids) {
      addAvp(Avp.create(dict, 265, Unsigned32(id), isMandatory: true));
    }
  }

  List<int> get authApplicationId =>
      _getList(258).map((v) => (v as Unsigned32).value).toList();
  set authApplicationId(List<int> ids) {
    _removeAvp(258);
    for (var id in ids) {
      addAvp(Avp.create(dict, 258, Unsigned32(id), isMandatory: true));
    }
  }

  void _setAvp(int code, AvpValue value) {
    _removeAvp(code);
    addAvp(Avp.create(dict, code, value, isMandatory: true));
  }

  void _removeAvp(int code) =>
      avps.removeWhere((avp) => avp.header.code == code);
  List<AvpValue> _getList(int code) =>
      avps.where((a) => a.header.code == code).map((a) => a.value).toList();
}
