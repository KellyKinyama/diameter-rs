// lib/avp/uri.dart

import 'dart:typed_data';
import 'dart:convert';
// import '../helpers/byte_reader.dart';
// import 'avp.dart';
// import 'octetstring.dart';
import '../diameter_rs.dart';

class DiameterURI extends AvpValue {
  final OctetString value;

  DiameterURI(Uint8List bytes) : value = OctetString(bytes);
  DiameterURI._(this.value);

  @override
  int get length => value.length;

  @override
  void encodeTo(BytesBuilder builder) {
    value.encodeTo(builder);
  }

  factory DiameterURI.decode(ByteReader reader, int length) {
    return DiameterURI._(OctetString.decode(reader, length));
  }

  @override
  String toString() {
    try {
      return utf8.decode(value.value);
    } catch (_) {
      return value.toString(); // Fallback to hex
    }
  }
}