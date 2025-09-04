// // lib/transport/codec.dart

// import 'dart:async';
// import 'dart:typed_data';

// import '../dictionary/dictionary.dart';
// import '../protocol/diameter_message.dart';

// /// A StreamTransformer that decodes a stream of bytes into Diameter messages.
// ///
// /// This codec handles message framing by reading the message length from
// /// the header and buffering data until a complete message is received.
// class DiameterCodec extends StreamTransformerBase<Uint8List, DiameterMessage> {
//   final Dictionary dict;

//   DiameterCodec(this.dict);

//   @override
//   Stream<DiameterMessage> bind(Stream<Uint8List> stream) {
//     final controller = StreamController<DiameterMessage>();
//     var buffer = BytesBuilder();

//     stream.listen(
//       (data) {
//         buffer.add(data);

//         // Process the buffer as long as it might contain complete messages.
//         while (true) {
//           var currentBytes = buffer.toBytes();
//           if (currentBytes.length < 4) {
//             // Not enough data to read the length, wait for more.
//             break;
//           }

//           // Read the 24-bit length from the header (bytes 1, 2, 3).
//           final length =
//               (currentBytes[1] << 16) |
//               (currentBytes[2] << 8) |
//               currentBytes[3];

//           if (currentBytes.length < length) {
//             // The full message has not yet arrived, wait for more data.
//             break;
//           }

//           // We have a complete message, extract it.
//           final messageBytes = currentBytes.sublist(0, length);
//           final message = DiameterMessage.decode(messageBytes, dict);
//           controller.add(message);

//           // Remove the processed message from the buffer.
//           final remainingBytes = currentBytes.sublist(length);
//           buffer = BytesBuilder()..add(remainingBytes);

//           // If no bytes are left, exit the loop.
//           if (remainingBytes.isEmpty) {
//             break;
//           }
//         }
//       },
//       onError: controller.addError,
//       onDone: controller.close,
//     );

//     return controller.stream;
//   }
// }
