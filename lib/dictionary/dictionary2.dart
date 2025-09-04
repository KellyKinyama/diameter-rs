// lib/dictionary/dictionary.dart

import 'package:xml/xml.dart';
// import '../protocol/diameter_message.dart';
// import '../avp/avp.dart';
// import 'default_dictionary_xml.dart'; // This import now works
import '../diameter_rs.dart';

/// Represents a key for an AVP, which can be just a code or a code/vendor pair.
class AvpKey {
  final int code;
  final int? vendorId;

  AvpKey(this.code, [this.vendorId]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvpKey &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          vendorId == other.vendorId;

  @override
  int get hashCode => code.hashCode ^ vendorId.hashCode;
}

/// Defines the properties of an AVP.
class AvpDefinition {
  final int code;
  final int? vendorId;
  final String name;
  final AvpType type;
  final bool mFlag;

  AvpDefinition({
    required this.code,
    this.vendorId,
    required this.name,
    required this.type,
    required this.mFlag,
  });
}

/// A dictionary holding definitions for AVPs, Commands, and Applications.
class Dictionary {
  final Map<AvpKey, AvpDefinition> avps = {};
  // The maps below are not used in this example but are good for a full implementation
  // final Map<String, int> applications = {};
  // final Map<String, int> commands = {};

  Dictionary();

  /// Creates and loads a dictionary from a list of XML strings.
  factory Dictionary.load(List<String> xmls) {
    final dict = Dictionary();
    for (var xml in xmls) {
      dict.loadXml(xml);
    }
    return dict;
  }

  /// Loads definitions from an XML string into the dictionary.
  void loadXml(String xml) {
    final document = XmlDocument.parse(xml);
    final applications = document.findAllElements('application');

    for (var appElement in applications) {
      for (var avpElement in appElement.findElements('avp')) {
        final name = avpElement.getAttribute('name')!;
        final code = int.parse(avpElement.getAttribute('code')!);
        final vendorIdStr = avpElement.getAttribute('vendor-id');
        final vendorId = vendorIdStr != null ? int.parse(vendorIdStr) : null;

        final must = avpElement.getAttribute('must') ?? "";
        final mFlag = must.contains('M');

        final typeStr = avpElement.getElement('data')!.getAttribute('type')!;
        final avpType = _parseAvpType(typeStr);

        addAvp(
          AvpDefinition(
            code: code,
            vendorId: vendorId,
            name: name,
            type: avpType,
            mFlag: mFlag,
          ),
        );
      }
    }
  }

  void addAvp(AvpDefinition avpDef) {
    avps[AvpKey(avpDef.code, avpDef.vendorId)] = avpDef;
  }

  AvpDefinition? getAvpDefinition(int code, [int? vendorId]) {
    if (vendorId != null) {
      var def = avps[AvpKey(code, vendorId)];
      if (def != null) return def;
    }
    return avps[AvpKey(code)];
  }

  AvpType _parseAvpType(String typeStr) {
    switch (typeStr) {
      case "UTF8String":
        return AvpType.utf8String;
      case "OctetString":
        return AvpType.octetString;
      case "Integer32":
        return AvpType.integer32;
      case "Integer64":
        return AvpType.integer64;
      case "Unsigned32":
        return AvpType.unsigned32;
      case "Unsigned64":
        return AvpType.unsigned64;
      case "Enumerated":
        return AvpType.enumerated;
      case "Grouped":
        return AvpType.grouped;
      case "DiameterIdentity":
        return AvpType.identity;
      case "DiameterURI":
        return AvpType.diameterURI;
      case "Time":
        return AvpType.time;
      case "Address":
        return AvpType.address;
      case "IPv4":
        return AvpType.addressIPv4;
      case "IPv6":
        return AvpType.addressIPv6;
      case "Float32":
        return AvpType.float32;
      case "Float64":
        return AvpType.float64;
      default:
        return AvpType.unknown;
    }
  }
}

/// A lazy-loaded singleton instance of the default dictionary.
late final defaultDictionary = Dictionary.load([defaultDictXml]);
