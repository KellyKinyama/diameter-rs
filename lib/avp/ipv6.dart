// lib/avp/ipv6.dart

import 'dart:io';
import 'dart:typed_data';
// import '../helpers/byte_reader.dart';
// import 'avp.dart';
import '../diameter_rs.dart';
class IPv6 extends AvpValue {
  final InternetAddress value;

  IPv6(this.value) {
    if (value.type != InternetAddressType.IPv6) {
      throw ArgumentError('Address must be IPv6');
    }
  }

  @override
  int get length => 16;

  @override
  void encodeTo(BytesBuilder builder) {
    builder.add(value.rawAddress);
  }

  factory IPv6.decode(ByteReader reader) {
    final bytes = reader.readBytes(16);
    return IPv6(InternetAddress.fromRawAddress(bytes));
  }

  @override
  String toString() => value.address;
}