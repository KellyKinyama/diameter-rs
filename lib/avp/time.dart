// lib/avp/time.dart

import 'dart:typed_data';
import '../helpers/byte_reader.dart';
import 'avp.dart';

// Difference between NTP epoch (1900-01-01) and Unix epoch (1970-01-01) in seconds.
const int ntpUnixEpochOffset = 2208988800;

class Time extends AvpValue {
  final DateTime value;

  Time(this.value);

  @override
  int get length => 4;

  @override
  void encodeTo(BytesBuilder builder) {
    final unixTimestamp = value.millisecondsSinceEpoch ~/ 1000;
    final ntpTimestamp = unixTimestamp + ntpUnixEpochOffset;
    var byteData = ByteData(4)..setUint32(0, ntpTimestamp, Endian.big);
    builder.add(byteData.buffer.asUint8List());
  }

  factory Time.decode(ByteReader reader) {
    final ntpTimestamp = reader.readUint32();
    final unixTimestamp = ntpTimestamp - ntpUnixEpochOffset;
    return Time(DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000, isUtc: true));
  }

  @override
  String toString() => value.toIso8601String();
}