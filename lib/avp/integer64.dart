// lib/avp/integer64.dart

import 'dart:typed_data';
// import '../helpers/byte_reader.dart';
// import 'avp.dart';
import '../diameter_rs.dart';

class Integer64 extends AvpValue {
  final BigInt value;
  Integer64(this.value);

  @override
  int get length => 8;

  @override
  void encodeTo(BytesBuilder builder) {
    var byteData = ByteData(8)..setInt64(0, value.toInt(), Endian.big);
    builder.add(byteData.buffer.asUint8List());
  }

  factory Integer64.decode(ByteReader reader) {
    return Integer64(reader.readInt64());
  }

  @override
  String toString() => value.toString();
}