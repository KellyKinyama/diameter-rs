// lib/avp/address.dart

import 'dart:io';
import 'dart:typed_data';
import '../helpers/byte_reader.dart';
import 'avp.dart';

/// The Address AVP data format.
/// It MUST be prefixed with a 2-byte Address Family value.
/// RFC 6733 Section 4.3.1
class Address extends AvpValue {
  /// Address Family Numbers from IANA registry. 1 for IPv4, 2 for IPv6.
  final int addressType;
  final Uint8List address;

  Address(this.addressType, this.address);

  /// Simple factory to create an Address AVP value from an IP address string.
  factory Address.fromString(String addressString) {
    final inetAddress = InternetAddress(addressString);
    if (inetAddress.type == InternetAddressType.IPv4) {
      return Address(1, inetAddress.rawAddress);
    } else if (inetAddress.type == InternetAddressType.IPv6) {
      return Address(2, inetAddress.rawAddress);
    }
    throw ArgumentError("Unsupported address type for: $addressString");
  }

  @override
  int get length => 2 + address.length; // 2 bytes for type + address length

  @override
  void encodeTo(BytesBuilder builder) {
    // This is the crucial part: The address MUST be prefixed with the 2-byte type.
    final byteData = ByteData(2)..setUint16(0, addressType, Endian.big);
    builder.add(byteData.buffer.asUint8List());
    builder.add(address);
  }

  factory Address.decode(ByteReader reader, int length) {
    if (length < 2) {
      throw Exception('Invalid Address AVP length');
    }
    final addressType = reader.readUint16();
    final address = reader.readBytes(length - 2);
    
    // Basic validation
    if (addressType == 1 && address.length != 4) {
      throw Exception('Invalid IPv4 address length in Address AVP');
    }
    if (addressType == 2 && address.length != 16) {
      throw Exception('Invalid IPv6 address length in Address AVP');
    }

    return Address(addressType, address);
  }

  @override
  String toString() {
    try {
      return InternetAddress.fromRawAddress(address).address;
    } catch (e) {
      return "Address (Type: $addressType, Value: $address)";
    }
  }
}