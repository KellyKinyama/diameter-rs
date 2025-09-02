// lib/avp/enumerated.dart

import 'dart:typed_data';
import '../helpers/byte_reader.dart';
import 'avp.dart';

class Enumerated extends AvpValue {
  final int value;
  Enumerated(this.value);

  @override
  int get length => 4;

  @override
  void encodeTo(BytesBuilder builder) {
    var byteData = ByteData(4)..setInt32(0, value);
    builder.add(byteData.buffer.asUint8List());
  }

  factory Enumerated.decode(ByteReader reader) {
    return Enumerated(reader.readInt32());
  }

  @override
  String toString() => value.toString();
}