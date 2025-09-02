// lib/avp/float64.dart

import 'dart:typed_data';
import '../helpers/byte_reader.dart';
import 'avp.dart';

class Float64 extends AvpValue {
  final double value;
  Float64(this.value);

  @override
  int get length => 8;

  @override
  void encodeTo(BytesBuilder builder) {
    var byteData = ByteData(8)..setFloat64(0, value, Endian.big);
    builder.add(byteData.buffer.asUint8List());
  }

  factory Float64.decode(ByteReader reader) {
    return Float64(reader.readFloat64());
  }

  @override
  String toString() => value.toString();
}