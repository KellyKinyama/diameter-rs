// lib/dictionary/dictionary.dart

import 'package:xml/xml.dart';
import '../diameter_rs.dart';
// import 'default_dictionary_xml.dart';

// AvpKey and AvpDefinition classes remain the same.
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
  final Map<String, ApplicationId> applications = {};
  final Map<String, CommandCode> commands = {};

  Dictionary();

  /// Creates and loads a dictionary from a list of XML strings.
  factory Dictionary.load(List<String> xmls) {
    final dict = Dictionary();
    for (var xml in xmls) {
      dict.loadXml(xml);
    }
    return dict;
  }

  /// FIXED: This method now parses AVPs at the root level AND inside applications.
  void loadXml(String xml) {
    final document = XmlDocument.parse(xml);
    final root = document.rootElement;

    // 1. Find and parse all AVP definitions directly under the <diameter> tag
    for (var avpElement in root.findElements('avp')) {
      _parseAndAddAvp(avpElement);
    }

    // 2. Find and parse all definitions inside each <application> tag
    for (var appElement in root.findElements('application')) {
      final appName = appElement.getAttribute('name')!;
      final appId = int.parse(appElement.getAttribute('id')!);
      applications[appName] = ApplicationId.fromId(appId);

      for (var cmdElement in appElement.findElements('command')) {
        final cmdName = cmdElement.getAttribute('name')!;
        final cmdCode = int.parse(cmdElement.getAttribute('code')!);
        commands[cmdName] = CommandCode.fromCode(cmdCode);
      }

      for (var avpElement in appElement.findElements('avp')) {
        _parseAndAddAvp(avpElement);
      }
    }
  }

  /// Helper function to parse an <avp> XmlElement and add it to the dictionary.
  void _parseAndAddAvp(XmlElement avpElement) {
    final name = avpElement.getAttribute('name')!;
    final code = int.parse(avpElement.getAttribute('code')!);
    final vendorIdStr = avpElement.getAttribute('vendor-id');
    final vendorId = vendorIdStr != null ? int.parse(vendorIdStr) : null;

    final must = avpElement.getAttribute('must') ?? "";
    final mFlag = must.contains('M');

    final dataElement = avpElement.getElement('data');
    if (dataElement == null) {
      print(
        "Warning: AVP '$name' (code $code) has no <data> element. Skipping.",
      );
      return;
    }
    final typeStr = dataElement.getAttribute('type')!;
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
      // You may need to add more types here if your dictionary uses them
      default:
        return AvpType.unknown;
    }
  }
}

/// A lazy-loaded singleton instance of the default dictionary.
late final defaultDictionary = Dictionary.load([defaultDictXml]);
