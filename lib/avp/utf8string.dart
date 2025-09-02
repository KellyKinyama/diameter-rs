// lib/avp/utf8string.dart

import 'dart:convert';
import 'dart:typed_data';
import '../error.dart';
import '../helpers/byte_reader.dart';
import 'avp.dart';

class Utf8String extends AvpValue {
  final String value;
  late final Uint8List _bytes;

  Utf8String(this.value) {
    _bytes = utf8.encode(value);
  }

  @override
  int get length => _bytes.length;

  @override
  void encodeTo(BytesBuilder builder) {
    builder.add(_bytes);
  }

  factory Utf8String.decode(ByteReader reader, int length) {
    final bytes = reader.readBytes(length);
    try {
      return Utf8String(utf8.decode(bytes));
    } catch (e) {
      throw DiameterException.decode('Invalid UTF8String: $e');
    }
  }

  @override
  String toString() => value;
}
