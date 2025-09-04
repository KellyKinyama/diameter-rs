// lib/avp/address.dart

import 'dart:io';
import 'dart:typed_data';
// import '../error.dart';
// import '../helpers/byte_reader.dart';
// import 'avp.dart';
import '../diameter_rs.dart';

/// Abstract base class for the value inside an Address AVP.
abstract class AddressValue {
  Uint8List getBytes();
  @override
  String toString();
}

class AddressIPv4Value extends AddressValue {
  final InternetAddress address;
  AddressIPv4Value(this.address);

  @override
  Uint8List getBytes() => address.rawAddress;
  @override
  String toString() => address.address;
}

class AddressIPv6Value extends AddressValue {
  final InternetAddress address;
  AddressIPv6Value(this.address);

  @override
  Uint8List getBytes() => address.rawAddress;
  @override
  String toString() => address.address;
}

class AddressE164Value extends AddressValue {
  final String address;
  AddressE164Value(this.address);

  @override
  Uint8List getBytes() => Uint8List.fromList(address.codeUnits);
  @override
  String toString() => address;
}

/// Represents the generic 'Address' AVP type.
class Address extends AvpValue {
  AddressValue value;

  Address(this.value);

  @override
  int get length => 2 + value.getBytes().length;

  @override
  void encodeTo(BytesBuilder builder) {
    var byteData = ByteData(2);
    if (value is AddressIPv4Value) {
      byteData.setUint16(0, 1);
    } else if (value is AddressIPv6Value) {
      byteData.setUint16(0, 2);
    } else if (value is AddressE164Value) {
      byteData.setUint16(0, 8);
    }
    builder.add(byteData.buffer.asUint8List());
    builder.add(value.getBytes());
  }

  factory Address.decode(ByteReader reader, int length) {
    final type = reader.readUint8() << 8 | reader.readUint8();
    final valueBytes = reader.readBytes(length - 2);

    switch (type) {
      case 1: // IPv4
        return Address(
          AddressIPv4Value(InternetAddress.fromRawAddress(valueBytes)),
        );
      case 2: // IPv6
        return Address(
          AddressIPv6Value(InternetAddress.fromRawAddress(valueBytes)),
        );
      case 8: // E164
        return Address(AddressE164Value(String.fromCharCodes(valueBytes)));
      default:
        throw DiameterException.decode('Unsupported address type: $type');
    }
  }

  @override
  String toString() => value.toString();
}
