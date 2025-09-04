// lib/protocol/diameter_message.dart

import 'dart:typed_data';
import '../diameter_rs.dart';
// import '../dictionary/dictionary.dart';
// import '../error.dart';
// import '../helpers/byte_reader.dart';
// import '../avp/avp.dart';
// import '../avp/unsigned32.dart';

const headerLength = 20;

/// Command Flags from RFC 6733.
class DiameterFlags {
  static const int REQUEST = 0x80;
  static const int PROXYABLE = 0x40;
  static const int ERROR = 0x20;
  static const int RETRANSMIT = 0x10;
}

/// Represents the header of a Diameter message.
class DiameterHeader {
  int version;
  int length;
  int flags;
  int code;
  int applicationId;
  int hopByHopId;
  int endToEndId;

  DiameterHeader({
    this.version = 1,
    required this.length,
    required this.flags,
    required this.code,
    required this.applicationId,
    required this.hopByHopId,
    required this.endToEndId,
  });

  /// Decodes a DiameterHeader from a byte reader.
  factory DiameterHeader.decode(ByteReader reader) {
    if (reader.remaining < headerLength) {
      throw DiameterException.decode('Invalid diameter header, too short');
    }
    final version = reader.readUint8();
    final length = reader.readUint24();
    final flags = reader.readUint8();
    final codeValue = reader.readUint24();
    final appIdValue = reader.readUint32();
    final hopByHopId = reader.readUint32();
    final endToEndId = reader.readUint32();

    return DiameterHeader(
      version: version,
      length: length,
      flags: flags,
      code: codeValue,
      applicationId: appIdValue,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
    );
  }

  /// Encodes the header to a byte builder.
  void encodeTo(BytesBuilder builder) {
    final byteData = ByteData(4);

    builder.addByte(version);

    byteData.setUint32(0, length, Endian.big);
    builder.add(byteData.buffer.asUint8List(1, 3));

    builder.addByte(flags);

    byteData.setUint32(0, code, Endian.big);
    builder.add(byteData.buffer.asUint8List(1, 3));

    byteData.setUint32(0, applicationId, Endian.big);
    builder.add(byteData.buffer.asUint8List(0, 4));

    byteData.setUint32(0, hopByHopId, Endian.big);
    builder.add(byteData.buffer.asUint8List(0, 4));

    byteData.setUint32(0, endToEndId, Endian.big);
    builder.add(byteData.buffer.asUint8List(0, 4));
  }
}

/// Represents a full Diameter message.
class DiameterMessage {
  DiameterHeader header;
  List<Avp> avps = [];
  Dictionary dict;

  DiameterMessage({required this.header, required this.dict, List<Avp>? avps})
    : avps = avps ?? [];

  /// Creates a new request or response message.
  factory DiameterMessage.create(
    int code,
    int applicationId,
    Dictionary dict, {
    int flags = 0,
    int? hopByHopId,
    int? endToEndId,
  }) {
    final header = DiameterHeader(
      length: headerLength,
      flags: flags,
      code: code,
      applicationId: applicationId,
      hopByHopId: hopByHopId ?? 0,
      endToEndId: endToEndId ?? 0,
    );
    return DiameterMessage(header: header, dict: dict);
  }

  /// Decodes a full DiameterMessage from bytes.
  factory DiameterMessage.decode(Uint8List data, Dictionary dict) {
    final reader = ByteReader(data);
    final header = DiameterHeader.decode(reader);

    if (data.lengthInBytes != header.length) {
      throw DiameterException.decode(
        'Message length mismatch in header vs actual data',
      );
    }

    final avps = <Avp>[];
    while (reader.remaining > 0) {
      final avp = Avp.decode(reader, dict);
      avps.add(avp);
    }

    return DiameterMessage(header: header, dict: dict, avps: avps);
  }

  /// Encodes the message to a Uint8List.
  Uint8List encode() {
    final builder = BytesBuilder();
    int totalAvpLength = 0;
    for (var avp in avps) {
      totalAvpLength += avp.header.length + avp.padding;
    }
    header.length = headerLength + totalAvpLength;

    header.encodeTo(builder);

    for (var avp in avps) {
      avp.encodeTo(builder);
    }

    return builder.toBytes();
  }

  /// Adds an AVP to the message.
  void addAvp(Avp avp) {
    avps.add(avp);
  }

  /// Finds the first AVP with the given code and optional vendorId.
  Avp? getAvp(int code, {int? vendorId}) {
    try {
      return avps.firstWhere(
        (avp) => avp.header.code == code && avp.header.vendorId == vendorId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Gets the value of the Result-Code AVP, if present.
  int? getResultCode() {
    final avp = getAvp(AvpCode.ResultCode);
    if (avp != null && avp.value is Unsigned32) {
      return (avp.value as Unsigned32).value;
    }
    return null;
  }
}

/// Common AVP Codes from RFC 6733
class AvpCode {
  static const int OriginHost = 264;
  static const int OriginRealm = 296;
  static const int HostIpAddress = 257;
  static const int VendorId = 266;
  static const int ProductName = 269;
  static const int ResultCode = 268;
  static const int FailedAvp = 279;
  static const int AuthApplicationId = 258;
}

/// Common Result-Code values from RFC 6733
class ResultCode {
  static const int DIAMETER_SUCCESS = 2001;
  static const int DIAMETER_UNABLE_TO_DELIVER = 3002;
  static const int DIAMETER_UNKNOWN_PEER = 3010;
  static const int DIAMETER_AVP_UNSUPPORTED = 5001;
}

/// Enumeration of Diameter Command Codes.
enum CommandCode {
  capabilitiesExchange(257),
  deviceWatchdog(280),
  disconnectPeer(282),
  reAuth(258),
  sessionTerminate(275),
  abortSession(274),
  creditControl(272),
  spendingLimit(8388635),
  spendingStatusNotification(8388636),
  accounting(271),
  aa(265),
  error(0);

  final int code;
  const CommandCode(this.code);

  static CommandCode fromCode(int code) {
    try {
      return values.firstWhere((e) => e.code == code);
    } catch (e) {
      // Safely return error code if not found
      return CommandCode.error;
    }
  }
}

/// Enumeration of Diameter Application IDs.
enum ApplicationId {
  common(0),
  accounting(3),
  creditControl(4),
  gx(16777238),
  rx(16777236),
  sy(16777302);

  final int id;
  const ApplicationId(this.id);

  static ApplicationId fromId(int id) {
    try {
      return values.firstWhere((e) => e.id == id);
    } catch (e) {
      // Throw a specific exception if the ID is unknown
      throw DiameterException.decode('Unknown application id: $id');
    }
  }
}
