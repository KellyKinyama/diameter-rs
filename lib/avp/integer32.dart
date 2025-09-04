// lib/avp/integer32.dart

import 'dart:typed_data';
// import '../helpers/byte_reader.dart';
// import 'avp.dart';
import '../diameter_rs.dart';

class Integer32 extends AvpValue {
  final int value;
  Integer32(this.value);

  @override
  int get length => 4;

  @override
  void encodeTo(BytesBuilder builder) {
    var byteData = ByteData(4)..setInt32(0, value, Endian.big);
    builder.add(byteData.buffer.asUint8List());
  }

  factory Integer32.decode(ByteReader reader) {
    return Integer32(reader.readInt32());
  }

  @override
  String toString() => value.toString();
}