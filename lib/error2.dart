// lib/error.dart

// import 'avp/avp.dart';
import '../diameter_rs.dart';

/// Base class for all Diameter-related exceptions.
class DiameterException implements Exception {
  final String message;
  final dynamic originalException;

  DiameterException(this.message, [this.originalException]);

  @override
  String toString() {
    if (originalException != null) {
      return 'DiameterException: $message (Caused by: $originalException)';
    }
    return 'DiameterException: $message';
  }

  // --- Factory constructors for specific internal error types ---

  factory DiameterException.decode(String msg) =>
      DiameterException('DecodeError: $msg');

  factory DiameterException.encode(String msg) =>
      DiameterException('EncodeError: $msg');

  factory DiameterException.unknownAvpCode(int code) =>
      DiameterException('Unknown AVP code: $code');

  factory DiameterException.client(String msg) =>
      DiameterException('ClientError: $msg');

  factory DiameterException.server(String msg) =>
      DiameterException('ServerError: $msg');

  /// Factory for creating a generic protocol error exception message.
  factory DiameterException.protocol(String message) =>
      DiameterException('Protocol Error: $message');
}

/// An exception representing a recoverable Diameter protocol error.
///
/// This is thrown when a message is syntactically valid but violates a
/// protocol rule (e.g., unsupported mandatory AVP). The server should catch
/// this and generate a proper Diameter error answer, rather than just closing
/// the connection.
class ProtocolErrorException extends DiameterException {
  /// The Diameter Result-Code to be sent in the answer (e.g., 5001).
  final int resultCode;

  /// The AVP that caused the error, to be included in the Failed-AVP.
  final Avp failedAvp;

  /// **FIXED:** The constructor now calls the generative super constructor
  /// with a formatted string, which is the correct Dart pattern.
  ProtocolErrorException(String message, this.resultCode, this.failedAvp)
    : super('Protocol Error: $message');
}
