// lib/avp/group.dart

import 'dart:typed_data';
import '../dictionary/dictionary.dart';
import '../helpers/byte_reader.dart';
import 'avp.dart';

class Grouped extends AvpValue {
  final List<Avp> avps;

  Grouped(this.avps);

  @override
  int get length {
    return avps.fold(0, (sum, avp) => sum + avp.header.length + avp.padding);
  }

  @override
  void encodeTo(BytesBuilder builder) {
    for (var avp in avps) {
      avp.encodeTo(builder);
    }
  }

  factory Grouped.decode(ByteReader reader, int length, Dictionary dict) {
    final avps = <Avp>[];
    final groupReader = ByteReader(reader.readBytes(length));
    
    while (groupReader.remaining > 0) {
      avps.add(Avp.decode(groupReader, dict));
    }
    return Grouped(avps);
  }

  @override
  String toString() => '{ ${avps.map((avp) => avp.toString()).join(", ")} }';
}