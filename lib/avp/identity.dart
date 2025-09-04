// lib/avp/identity.dart

import 'dart:typed_data';
// import '../helpers/byte_reader.dart';
// import 'avp.dart';
// import 'utf8string.dart';
import '../diameter_rs.dart';

class Identity extends AvpValue {
  final Utf8String value;

  Identity(String stringValue) : value = Utf8String(stringValue);
  Identity._(this.value);

  @override
  int get length => value.length;

  @override
  void encodeTo(BytesBuilder builder) {
    value.encodeTo(builder);
  }

  factory Identity.decode(ByteReader reader, int length) {
    return Identity._(Utf8String.decode(reader, length));
  }

  @override
  String toString() => value.toString();
}