// lib/avp/float32.dart

import 'dart:typed_data';
import '../helpers/byte_reader.dart';
import 'avp.dart';

class Float32 extends AvpValue {
  final double value;
  Float32(this.value);

  @override
  int get length => 4;

  @override
  void encodeTo(BytesBuilder builder) {
    var byteData = ByteData(4)..setFloat32(0, value, Endian.big);
    builder.add(byteData.buffer.asUint8List());
  }

  factory Float32.decode(ByteReader reader) {
    return Float32(reader.readFloat32());
  }

  @override
  String toString() => value.toString();
}