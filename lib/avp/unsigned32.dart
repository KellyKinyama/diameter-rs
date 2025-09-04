// lib/avp/unsigned32.dart

import 'dart:typed_data';
// import '../helpers/byte_reader.dart';
// import 'avp.dart';
import '../diameter_rs.dart';

class Unsigned32 extends AvpValue {
  final int value;
  Unsigned32(this.value);

  @override
  int get length => 4;

  @override
  void encodeTo(BytesBuilder builder) {
    var byteData = ByteData(4)..setUint32(0, value, Endian.big);
    builder.add(byteData.buffer.asUint8List());
  }

  factory Unsigned32.decode(ByteReader reader) {
    return Unsigned32(reader.readUint32());
  }

  @override
  String toString() => value.toString();
}