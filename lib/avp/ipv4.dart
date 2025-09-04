// lib/avp/ipv4.dart

import 'dart:io';
import 'dart:typed_data';
// import '../helpers/byte_reader.dart';
// import 'avp.dart';
import '../diameter_rs.dart';

class IPv4 extends AvpValue {
  final InternetAddress value;

  IPv4(this.value) {
    if (value.type != InternetAddressType.IPv4) {
      throw ArgumentError('Address must be IPv4');
    }
  }

  @override
  int get length => 4;

  @override
  void encodeTo(BytesBuilder builder) {
    builder.add(value.rawAddress);
  }

  factory IPv4.decode(ByteReader reader) {
    final bytes = reader.readBytes(4);
    return IPv4(InternetAddress.fromRawAddress(bytes));
  }

  @override
  String toString() => value.address;
}