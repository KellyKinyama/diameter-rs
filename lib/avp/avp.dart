// lib/avp/avp.dart

import 'dart:typed_data';
import '../diameter_rs.dart';
// import '../dictionary/dictionary.dart';
// import '../error.dart';
// import '../helpers/byte_reader.dart';

// Import all specific AVP types
// import 'address.dart';
// import 'enumerated.dart';
// import 'float32.dart';
// import 'float64.dart';
// import 'group.dart';
// import 'identity.dart';
// import 'integer32.dart';
// import 'integer64.dart';
// import 'ipv4.dart';
// import 'ipv6.dart';
// import 'octetstring.dart';
// import 'time.dart';
// import 'unsigned32.dart';
// import 'unsigned64.dart';
// import 'uri.dart';
// import 'utf8string.dart';

/// AVP Flags as defined in RFC 6733.
class AvpFlags {
  static const int VENDOR = 0x80;
  static const int MANDATORY = 0x40;
  static const int PRIVATE = 0x20;
}

/// Enum representing the data type of an AVP, derived from the dictionary.
enum AvpType {
  unknown,
  address,
  addressIPv4,
  addressIPv6,
  identity,
  diameterURI,
  enumerated,
  float32,
  float64,
  grouped,
  integer32,
  integer64,
  octetString,
  time,
  unsigned32,
  unsigned64,
  utf8String,
}

/// Represents the header of an AVP.
class AvpHeader {
  int code;
  bool isVendorSpecific;
  bool isMandatory;
  bool isPrivate;
  int length;
  int? vendorId;

  AvpHeader({
    required this.code,
    required this.isVendorSpecific,
    required this.isMandatory,
    required this.isPrivate,
    required this.length,
    this.vendorId,
  });

  /// Decodes an AVP header from a byte reader.
  factory AvpHeader.decode(ByteReader reader) {
    final code = reader.readUint32();
    final flags = reader.readUint8();
    final length = reader.readUint24();

    final isVendorSpecific = (flags & AvpFlags.VENDOR) != 0;

    int? vendorId;
    if (isVendorSpecific) {
      vendorId = reader.readUint32();
    }

    return AvpHeader(
      code: code,
      isVendorSpecific: isVendorSpecific,
      isMandatory: (flags & AvpFlags.MANDATORY) != 0,
      isPrivate: (flags & AvpFlags.PRIVATE) != 0,
      length: length,
      vendorId: vendorId,
    );
  }

  /// Encodes the header to a byte builder.
  void encodeTo(BytesBuilder builder) {
    var byteData = ByteData(4)..setUint32(0, code);
    builder.add(byteData.buffer.asUint8List());

    int flags = 0;
    if (isVendorSpecific) flags |= AvpFlags.VENDOR;
    if (isMandatory) flags |= AvpFlags.MANDATORY;
    if (isPrivate) flags |= AvpFlags.PRIVATE;
    builder.addByte(flags);

    byteData.setUint32(0, length);
    builder.add([
      byteData.getUint8(1),
      byteData.getUint8(2),
      byteData.getUint8(3),
    ]);

    if (isVendorSpecific) {
      byteData.setUint32(0, vendorId!);
      builder.add(byteData.buffer.asUint8List());
    }
  }
}

/// Abstract base class for all AVP value types.
abstract class AvpValue {
  /// The length of the AVP's data payload in bytes.
  int get length;

  /// Encodes the AVP's data payload to a byte builder.
  void encodeTo(BytesBuilder builder);
}

/// Represents a complete Attribute-Value Pair.
class Avp {
  AvpHeader header;
  AvpValue value;
  int padding;
  Dictionary dict;

  Avp._({
    required this.header,
    required this.value,
    required this.padding,
    required this.dict,
  });

  /// Creates a new AVP instance, automatically calculating length and padding.
  factory Avp.create(
    Dictionary dict,
    int code,
    AvpValue value, {
    int? vendorId,
    bool isMandatory = false,
    bool isPrivate = false,
  }) {
    final bool isVendorSpecific = vendorId != null;
    final int headerLength = isVendorSpecific ? 12 : 8;
    final int valueLength = value.length;
    final int padding = (4 - (valueLength % 4)) % 4;

    final header = AvpHeader(
      code: code,
      isVendorSpecific: isVendorSpecific,
      isMandatory: isMandatory,
      isPrivate: isPrivate,
      length: headerLength + valueLength,
      vendorId: vendorId,
    );

    return Avp._(header: header, value: value, padding: padding, dict: dict);
  }

  /// Decodes a complete AVP from a byte reader using a dictionary.
  factory Avp.decode(ByteReader reader, Dictionary dict) {
    final header = AvpHeader.decode(reader);
    final headerLength = header.isVendorSpecific ? 12 : 8;
    final valueLength = header.length - headerLength;

    final def = dict.getAvpDefinition(header.code, header.vendorId);
    if (def == null) {
      throw DiameterException.unknownAvpCode(header.code);
    }

    final value = _decodeValue(def.type, reader, valueLength, dict);
    final padding = (4 - (valueLength % 4)) % 4;
    reader.skip(padding);

    return Avp._(header: header, value: value, padding: padding, dict: dict);
  }

  /// **FIXED: This method was missing.**
  /// Encodes the entire AVP (header, value, padding) to a byte builder.
  void encodeTo(BytesBuilder builder) {
    header.encodeTo(builder);
    value.encodeTo(builder);
    if (padding > 0) {
      // Adds the required number of zero bytes for padding.
      builder.add(Uint8List(padding));
    }
  }

  static AvpValue _decodeValue(
    AvpType type,
    ByteReader reader,
    int length,
    Dictionary dict,
  ) {
    switch (type) {
      case AvpType.address:
        return Address.decode(reader, length);
      case AvpType.addressIPv4:
        return IPv4.decode(reader);
      case AvpType.addressIPv6:
        return IPv6.decode(reader);
      case AvpType.enumerated:
        return Enumerated.decode(reader);
      case AvpType.float32:
        return Float32.decode(reader);
      case AvpType.float64:
        return Float64.decode(reader);
      case AvpType.grouped:
        return Grouped.decode(reader, length, dict);
      case AvpType.identity:
        return Identity.decode(reader, length);
      case AvpType.integer32:
        return Integer32.decode(reader);
      case AvpType.integer64:
        return Integer64.decode(reader);
      case AvpType.octetString:
        return OctetString.decode(reader, length);
      case AvpType.time:
        return Time.decode(reader);
      case AvpType.unsigned32:
        return Unsigned32.decode(reader);
      case AvpType.unsigned64:
        return Unsigned64.decode(reader);
      case AvpType.utf8String:
        return Utf8String.decode(reader, length);
      case AvpType.diameterURI:
        return DiameterURI.decode(reader, length);
      case AvpType.unknown:
        throw DiameterException.decode("Cannot decode AVP of type Unknown");
    }
  }
}
