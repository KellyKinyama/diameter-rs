// test/diameter_test.dart

import 'dart:typed_data';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:diameter_rs/avp/avp.dart';
import 'package:test/test.dart';
import 'package:diameter_rs/diameter_rs.dart';
import 'package:diameter_rs/helpers/byte_reader.dart';

//-///////////////////////////////////////////////////////////////////////////
// Test Data and Helper Functions
//-///////////////////////////////////////////////////////////////////////////

Uint8List testData1() {
  return Uint8List.fromList([
    0x01, 0x00, 0x00, 0x14, // version, length
    0x80, 0x00, 0x01, 0x10, // flags, code
    0x00, 0x00, 0x00, 0x04, // application_id
    0x00, 0x00, 0x00, 0x03, // hop_by_hop_id
    0x00, 0x00, 0x00, 0x04, // end_to_end_id
  ]);
}

Uint8List testData2() {
  return Uint8List.fromList([
    0x01, 0x00, 0x00, 0x34, // version, length
    0x80, 0x00, 0x01, 0x10, // flags, code
    0x00, 0x00, 0x00, 0x04, // application_id
    0x00, 0x00, 0x00, 0x03, // hop_by_hop_id
    0x00, 0x00, 0x00, 0x04, // end_to_end_id
    0x00, 0x00, 0x01, 0x9F, // avp code (415)
    0x40, 0x00, 0x00, 0x0C, // flags, length
    0x00, 0x00, 0x04, 0xB0, // value (1200)
    0x00, 0x00, 0x00, 0x1E, // avp code (30)
    0x00, 0x00, 0x00, 0x12, // flags, length
    0x66, 0x6F, 0x6F, 0x62, // value "foob"
    0x61, 0x72, 0x31, 0x32, // value "ar12"
    0x33, 0x34, 0x00, 0x00, // value "34" + padding
  ]);
}

DiameterMessage createCcaMessage(Dictionary dict) {
  var message = DiameterMessage.create(
    CommandCode.creditControl,
    ApplicationId.creditControl,
    dict,
    flags: DiameterFlags.REQUEST | DiameterFlags.PROXYABLE,
    hopByHopId: 1123158610,
    endToEndId: 3102381851,
  );

  message.addAvp(
    Avp.create(dict, 264, Identity("host.example.com"), isMandatory: true),
  );
  message.addAvp(
    Avp.create(dict, 296, Identity("realm.example.com"), isMandatory: true),
  );
  message.addAvp(
    Avp.create(dict, 263, Utf8String("ses;12345888"), isMandatory: true),
  );
  message.addAvp(Avp.create(dict, 268, Unsigned32(2001), isMandatory: true));
  message.addAvp(Avp.create(dict, 416, Enumerated(1), isMandatory: true));
  message.addAvp(Avp.create(dict, 415, Unsigned32(1000), isMandatory: true));

  var psInformation = Grouped([
    Avp.create(dict, 30, Utf8String("10999"), isMandatory: true),
  ]);

  var serviceInformation = Grouped([
    Avp.create(dict, 874, psInformation, vendorId: 10415, isMandatory: true),
  ]);

  message.addAvp(
    Avp.create(
      dict,
      873,
      serviceInformation,
      vendorId: 10415,
      isMandatory: true,
    ),
  );

  return message;
}

//-///////////////////////////////////////////////////////////////////////////
// Benchmark Classes
//-///////////////////////////////////////////////////////////////////////////

class DecodeHeaderBenchmark extends BenchmarkBase {
  final data = testData1();
  DecodeHeaderBenchmark() : super("Decode Header");

  @override
  void run() {
    DiameterHeader.decode(ByteReader(data));
  }
}

class EncodeHeaderBenchmark extends BenchmarkBase {
  late final DiameterHeader header;
  EncodeHeaderBenchmark() : super("Encode Header") {
    header = DiameterHeader.decode(ByteReader(testData1()));
  }

  @override
  void run() {
    final builder = BytesBuilder();
    header.encodeTo(builder);
    builder.toBytes();
  }
}

class DecodeMessageBenchmark extends BenchmarkBase {
  final data = testData2();
  final dict = defaultDictionary;
  DecodeMessageBenchmark() : super("Decode Message");

  @override
  void run() {
    DiameterMessage.decode(data, dict);
  }
}

class EncodeMessageBenchmark extends BenchmarkBase {
  late final DiameterMessage message;
  EncodeMessageBenchmark() : super("Encode Message") {
    message = DiameterMessage.decode(testData2(), defaultDictionary);
  }

  @override
  void run() {
    message.encode();
  }
}

class DecodeCcaBenchmark extends BenchmarkBase {
  late final Uint8List data;
  final dict = defaultDictionary;
  DecodeCcaBenchmark() : super("Decode CCA Message") {
    final message = createCcaMessage(dict);
    data = message.encode();
  }

  @override
  void run() {
    DiameterMessage.decode(data, dict);
  }
}

class EncodeCcaBenchmark extends BenchmarkBase {
  late final DiameterMessage message;
  EncodeCcaBenchmark() : super("Encode CCA Message") {
    message = createCcaMessage(defaultDictionary);
  }

  @override
  void run() {
    message.encode();
  }
}

//-///////////////////////////////////////////////////////////////////////////
// Main Function to run Tests and Benchmarks
//-///////////////////////////////////////////////////////////////////////////

void main() {
  // ==================== Unit Tests ====================
  group('Diameter Protocol', () {
    final dict = defaultDictionary;

    test('Correctly decodes a simple header', () {
      final data = testData1();
      final header = DiameterHeader.decode(ByteReader(data));

      expect(header.version, 1);
      expect(header.length, 20);
      expect(header.flags, DiameterFlags.REQUEST);
      expect(header.code, CommandCode.creditControl);
      expect(header.applicationId, ApplicationId.creditControl);
      expect(header.hopByHopId, 3);
      expect(header.endToEndId, 4);
    });

    test('Correctly encodes a simple header', () {
      final data = testData1();
      final header = DiameterHeader.decode(ByteReader(data));
      final builder = BytesBuilder();
      header.encodeTo(builder);
      final encodedData = builder.toBytes();

      expect(encodedData, equals(data));
    });

    test('Correctly decodes a message with AVPs', () {
      final data = testData2();
      final message = DiameterMessage.decode(data, dict);

      expect(message.avps.length, 2);
      final avp1 = message.avps[0];
      final avp2 = message.avps[1];

      expect(avp1.header.code, 415);
      expect(avp1.header.isMandatory, true);
      expect((avp1.value as Unsigned32).value, 1200);

      expect(avp2.header.code, 30);
      expect(avp2.header.isMandatory, false);
      expect((avp2.value as Utf8String).value, "foobar1234");
    });

    test(
      'Encode and Decode cycle produces identical results for a complex message',
      () {
        final message = createCcaMessage(dict);
        final encodedBytes = message.encode();
        final decodedMessage = DiameterMessage.decode(encodedBytes, dict);

        expect(decodedMessage.header.code, message.header.code);
        expect(decodedMessage.avps.length, message.avps.length);

        final originalOriginHost =
            (message.getAvp(264)!.value as Identity).value;
        final decodedOriginHost =
            (decodedMessage.getAvp(264)!.value as Identity).value;
        expect(decodedOriginHost.toString(), originalOriginHost.toString());
      },
    );
  });

  // ==================== Benchmarks ====================
  print("\nRunning benchmarks...\n");
  DecodeHeaderBenchmark().report();
  EncodeHeaderBenchmark().report();
  DecodeMessageBenchmark().report();
  EncodeMessageBenchmark().report();
  DecodeCcaBenchmark().report();
  EncodeCcaBenchmark().report();
}
