// lib/diameter.dart

/// A Dart implementation of the Diameter Protocol, based on RFC 6733.
/// This library provides tools for creating Diameter clients and servers,
/// handling messages, and managing AVP dictionaries.

// Core Protocol
export 'protocol/diameter_message.dart';
export 'dictionary/default_dictionary_xml.dart';
// AVP Types
export 'avp/address.dart';
export 'avp/enumerated.dart';
export 'avp/float32.dart';
export 'avp/float64.dart';
export 'avp/group.dart';
export 'avp/identity.dart';
export 'avp/integer32.dart';
export 'avp/integer64.dart';
export 'avp/ipv4.dart';
export 'avp/ipv6.dart';
export 'avp/octetstring.dart';
export 'avp/time.dart';
export 'avp/unsigned32.dart';
export 'avp/unsigned64.dart';
export 'avp/uri.dart';
export 'avp/utf8string.dart';
export 'avp/avp.dart';
export 'avp/generator.dart';
export 'applications/message_generator.dart';

// Dictionary
export 'dictionary/dictionary3.dart';

// Error Handling
export 'error2.dart';

// Transport Layer
export 'transport/client2.dart';
export 'transport/server2.dart';
export 'transport/peer.dart';

export 'helpers/byte_reader.dart';
export 'applications/base_application.dart';

//applications
// export 'applications/credit_control/credit_control.dart';
export 'applications/credit_control/credit_control_messages.dart';
export 'applications/base/capabilities_exchange.dart';
