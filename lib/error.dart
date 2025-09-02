// lib/error.dart

/// Custom exception class for the Diameter library.
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

  factory DiameterException.decode(String msg) =>
      DiameterException('DecodeError: $msg');
  factory DiameterException.encode(String msg) =>
      DiameterException('EncodeError: $msg');
  factory DiameterException.unknownAvpCode(int code) =>
      DiameterException('Unknown AVP code: $code');
  factory DiameterException.unknownAvpName(String name) =>
      DiameterException('Unknown AVP name: $name');
  factory DiameterException.client(String msg) =>
      DiameterException('ClientError: $msg');
  factory DiameterException.server(String msg) =>
      DiameterException('ServerError: $msg');
}