// lib/avp/unsigned64.dart

import 'dart:typed_data';
// import '../helpers/byte_reader.dart';
// import 'avp.dart';
import '../diameter_rs.dart';

class Unsigned64 extends AvpValue {
  final int value;
  Unsigned64(this.value);

  @override
  int get length => 8;

  @override
  void encodeTo(BytesBuilder builder) {
    var byteData = ByteData(8)..setUint64(0, value.toInt(), Endian.big);
    builder.add(byteData.buffer.asUint8List());
  }

  factory Unsigned64.decode(ByteReader reader) {
    return Unsigned64(reader.readUint64());
  }

  @override
  String toString() => value.toString();
}
