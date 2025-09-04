// lib/avp/octetstring.dart

import 'dart:typed_data';
// import '../helpers/byte_reader.dart';
// import 'avp.dart';
import '../diameter_rs.dart';
class OctetString extends AvpValue {
  final Uint8List value;

  OctetString(this.value);
  
  @override
  int get length => value.length;

  @override
  void encodeTo(BytesBuilder builder) {
    builder.add(value);
  }

  factory OctetString.decode(ByteReader reader, int length) {
    return OctetString(reader.readBytes(length));
  }

  @override
  String toString() => value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}