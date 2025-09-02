// lib/protocol/diameter_message.dart

import 'dart:typed_data';
import '../dictionary/dictionary.dart';
import '../error.dart';
import '../helpers/byte_reader.dart';
import '../avp/avp.dart';

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
  CommandCode code;
  ApplicationId applicationId;
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

    final code = CommandCode.fromCode(codeValue);
    final appId = ApplicationId.fromId(appIdValue);

    return DiameterHeader(
      version: version,
      length: length,
      flags: flags,
      code: code,
      applicationId: appId,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
    );
  }

  /// **FIXED: This method has been rewritten to be correct and clear.**
  /// Encodes the header to a byte builder.
  void encodeTo(BytesBuilder builder) {
    // Use a temporary buffer just for integer conversions.
    final byteData = ByteData(8);

    // Version (1 byte)
    builder.addByte(version);

    // Length (3 bytes)
    byteData.setUint32(0, length, Endian.big);
    builder.add(byteData.buffer.asUint8List(1, 3));

    // Flags (1 byte)
    builder.addByte(flags);

    // Code (3 bytes)
    byteData.setUint32(0, code.code, Endian.big);
    builder.add(byteData.buffer.asUint8List(1, 3));

    // Application ID (4 bytes)
    byteData.setUint32(0, applicationId.id, Endian.big);
    builder.add(byteData.buffer.asUint8List(0, 4));

    // Hop-by-Hop ID (4 bytes)
    byteData.setUint32(0, hopByHopId, Endian.big);
    builder.add(byteData.buffer.asUint8List(0, 4));

    // End-to-End ID (4 bytes)
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
    CommandCode code,
    ApplicationId applicationId,
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

    // Recalculate length before encoding header
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

  /// Finds the first AVP with the given code.
  Avp? getAvp(int code) {
    try {
      return avps.firstWhere((avp) => avp.header.code == code);
    } catch (e) {
      return null;
    }
  }
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
