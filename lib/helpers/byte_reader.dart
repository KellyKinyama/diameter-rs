// lib/helpers/byte_reader.dart

import 'dart:typed_data';

/// A utility to read data sequentially from a Uint8List.
class ByteReader {
  final Uint8List _data;
  final ByteData _byteData;
  int _offset = 0;

  ByteReader(this._data) : _byteData = _data.buffer.asByteData();

  int get remaining => _data.lengthInBytes - _offset;
  int get offset => _offset;

  void skip(int bytes) {
    _offset += bytes;
  }

  int readUint8() {
    final val = _byteData.getUint8(_offset);
    _offset += 1;
    return val;
  }

  int readUint24() {
    final val = (_byteData.getUint8(_offset) << 16) |
                (_byteData.getUint8(_offset + 1) << 8) |
                _byteData.getUint8(_offset + 2);
    _offset += 3;
    return val;
  }

  int readUint32() {
    final val = _byteData.getUint32(_offset, Endian.big);
    _offset += 4;
    return val;
  }

  int readInt32() {
    final val = _byteData.getInt32(_offset, Endian.big);
    _offset += 4;
    return val;
  }
  
  BigInt readUint64() {
    final val = _byteData.getUint64(_offset, Endian.big);
    _offset += 8;
    return BigInt.from(val);
  }

  BigInt readInt64() {
    final val = _byteData.getInt64(_offset, Endian.big);
    _offset += 8;
    return BigInt.from(val);
  }

  double readFloat32() {
    final val = _byteData.getFloat32(_offset, Endian.big);
    _offset += 4;
    return val;
  }
  
  double readFloat64() {
    final val = _byteData.getFloat64(_offset, Endian.big);
    _offset += 8;
    return val;
  }

  Uint8List readBytes(int length) {
    final bytes = _data.sublist(_offset, _offset + length);
    _offset += length;
    return bytes;
  }
}