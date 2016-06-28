part of msgpack;

Uint8List pack(value) {
  if (_statefulPacker == null) {
    _statefulPacker = new StatefulPacker();
  }
  _statefulPacker.pack(value);
  return _statefulPacker.done();
}

StatefulPacker _statefulPacker;

class PackedReference {
  final List<int> data;

  PackedReference(this.data);
}

class Float {
  final double value;

  Float(this.value);

  @override
  String toString() => value.toString();
}

class BinaryHelper {
  static ByteData create(input) {
    if (input is ByteData) {
      return input;
    } else if (input is TypedData) {
      return input.buffer.asByteData();
    } else if (input is ByteBuffer) {
      return input.asByteData();
    } else if (input is List<int>) {
      return new Uint8List.fromList(input).buffer.asByteData();
    } else if (input is String) {
      var encoded = _toUTF8(input);
      if (encoded is Uint8List) {
        return encoded.buffer.asByteData();
      } else {
        return new Uint8List.fromList(encoded).buffer.asByteData();
      }
    } else if (input == null) {
      return null;
    }

    throw new Exception("Unsupported input to convert to binary");
  }
}

abstract class PackBuffer {
  void writeUint8(int b);
  void writeUint16(int value);
  void writeUint32(int value);
  void writeUint8List(Uint8List list);

  Uint8List done();
}

class MsgPackBuffer implements PackBuffer {
  static const int defaultBufferSize = const int.fromEnvironment(
    "msgpack.packer.defaultBufferSize",
    defaultValue: 512
  );

  List<Uint8List> _buffers = <Uint8List>[];
  Uint8List _buffer;
  int _len = 0;
  int _offset = 0;
  int _totalLength = 0;

  final int bufferSize;

  MsgPackBuffer({this.bufferSize: defaultBufferSize});

  void _checkBuffer() {
    if (_buffer == null) {
      _buffer = new Uint8List(bufferSize);
    }
  }

  @override
  void writeUint8(int byte) {
    if (_buffer == null) {
      _buffer = new Uint8List(bufferSize);
    }

    if (_buffer.lengthInBytes == _len) {
      _buffers.add(_buffer);
      _buffer = new Uint8List(bufferSize);
      _len = 0;
      _offset = 0;
    }

    _buffer[_offset] = byte;
    _offset++;
    _len++;
    _totalLength++;
  }

  @override
  void writeUint16(int value) {
    _checkBuffer();

    if ((_buffer.lengthInBytes - _len) < 2) {
      writeUint8((value >> 8) & 0xff);
      writeUint8(value & 0xff);
    } else {
      _buffer[_offset++] = (value >> 8) & 0xff;
      _buffer[_offset++] = value & 0xff;
      _len += 2;
      _totalLength += 2;
    }
  }

  @override
  void writeUint32(int value) {
    _checkBuffer();

    if ((_buffer.lengthInBytes - _len) < 4) {
      writeUint8((value >> 24) & 0xff);
      writeUint8((value >> 16) & 0xff);
      writeUint8((value >> 8) & 0xff);
      writeUint8(value & 0xff);
    } else {
      _buffer[_offset++] = (value >> 24) & 0xff;
      _buffer[_offset++] = (value >> 16) & 0xff;
      _buffer[_offset++] = (value >> 8) & 0xff;
      _buffer[_offset++] = value & 0xff;
      _len += 4;
      _totalLength += 4;
    }
  }

  Uint8List read() {
    var out = new Uint8List(_totalLength);
    var off = 0;

    var bufferCount = _buffers.length;
    for (var i = 0; i < bufferCount; i++) {
      Uint8List buff = _buffers[i];

      for (var x = 0; x < buff.lengthInBytes; x++) {
        out[off] = buff[x];
        off++;
      }
    }

    if (_buffer != null) {
      for (var i = 0; i < _len; i++) {
        out[off] = _buffer[i];
        off++;
      }
    }

    return out;
  }

  @override
  Uint8List done() {
    Uint8List out = read();
    _buffers = new List<Uint8List>();
    _len = 0;
    _totalLength = 0;
    _offset = 0;
    _buffer = null;
    return out;
  }

  @override
  void writeUint8List(Uint8List data) {
    _checkBuffer();

    var dataSize = data.lengthInBytes;

    var bufferSpace = _buffer.lengthInBytes - _len;

    if (bufferSpace < dataSize) {
      int i;
      for (i = 0; i < bufferSpace; i++) {
        _buffer[_offset++] = data[i];
      }

      _len += bufferSpace;
      _totalLength += bufferSpace;

      while(i < dataSize) {
        writeUint8(data[i++]);
      }
    } else {
      for (var i = 0; i < dataSize; i++) {
        _buffer[_offset++] = data[i];
      }

      _len += dataSize;
      _totalLength += dataSize;
    }
  }
}

class StatefulPacker {
  PackBuffer buffer;

  StatefulPacker([this.buffer]) {
    if (buffer == null) {
      buffer = new MsgPackBuffer();
    }
  }

  void pack(value) {
    if (value is Iterable && value is! List) {
      value = value.toList();
    }

    if (value == null) {
      buffer.writeUint8(0xc0);
    } else if (value == false) {
      buffer.writeUint8(0xc2);
    } else if (value == true) {
      buffer.writeUint8(0xc3);
    } else if (value is int) {
      packInt(value);
    } else if (value is String) {
      packString(value);
    } else if (value is List) {
      packList(value);
    } else if (value is Map) {
      packMap(value);
    } else if (value is double) {
      packDouble(value);
    } else if (value is Float) {
      packFloat(value);
    } else if (value is ByteData) {
      packBinary(value);
    } else if (value is PackedReference) {
      writeAllBytes(value.data);
    } else {
      throw new Exception("Failed to pack value: ${value}");
    }
  }

  void packAll(values) {
    for (var value in values) {
      pack(value);
    }
  }

  void packBinary(ByteData data) {
    var list = data.buffer.asUint8List(
      data.offsetInBytes, data.lengthInBytes);

    var count = list.lengthInBytes;

    if (count <= 255) {
      buffer.writeUint8(0xc4);
      buffer.writeUint8(count);
      writeAllBytes(list);
    } else if (count <= 65535) {
      buffer.writeUint8(0xc5);
      buffer.writeUint16(count);
      writeAllBytes(list);
    } else {
      buffer.writeUint8(0xc6);
      buffer.writeUint32(count);
      writeAllBytes(list);
    }
  }

  void packInt(int value) {
    if (value >= 0 && value < 128) {
      buffer.writeUint8(value);
      return;
    }

    if (value < 0) {
      if (value >= -32) {
        buffer.writeUint8(0xe0 + value + 32);
      } else if (value > -0x80) {
        buffer.writeUint8(0xd0);
        buffer.writeUint8(value + 0x100);
      } else if (value > -0x8000) {
        buffer.writeUint8(0xd1);
        buffer.writeUint16(value + 0x10000);
      } else if (value > -0x80000000) {
        buffer.writeUint8(0xd2);
        buffer.writeUint32(value + 0x100000000);
      } else {
        buffer.writeUint8(0xd3);
        _encodeUint64(value);
      }
    } else {
      if (value < 0x100) {
        buffer.writeUint8(0xcc);
        buffer.writeUint8(value);
      } else if (value < 0x10000) {
        buffer.writeUint8(0xcd);
        buffer.writeUint16(value);
      } else if (value < 0x100000000) {
        buffer.writeUint8(0xce);
        buffer.writeUint32(value);
      } else {
        buffer.writeUint8(0xcf);
        _encodeUint64(value);
      }
    }
  }

  void _encodeUint64(int value) {
    var high = (value / 0x100000000).floor();
    var low = value & 0xffffffff;
    buffer.writeUint8((high >> 24) & 0xff);
    buffer.writeUint8((high >> 16) & 0xff);
    buffer.writeUint8((high >>  8) & 0xff);
    buffer.writeUint8(high & 0xff);
    buffer.writeUint8((low  >> 24) & 0xff);
    buffer.writeUint8((low  >> 16) & 0xff);
    buffer.writeUint8((low  >>  8) & 0xff);
    buffer.writeUint8(low & 0xff);
  }

  static const Utf8Encoder _utf8Encoder = const Utf8Encoder();

  void packString(String value) {
    List<int> utf8;

    if (StringCache.has(value)) {
      utf8 = StringCache.get(value);
    } else {
      utf8 = _toUTF8(value);
    }

    if (utf8.length < 0x20) {
      buffer.writeUint8(0xa0 + utf8.length);
    } else if (utf8.length < 0x100) {
      buffer.writeUint8(0xd9);
      buffer.writeUint8(utf8.length);
    } else if (utf8.length < 0x10000) {
      buffer.writeUint8(0xda);
      buffer.writeUint16(utf8.length);
    } else {
      buffer.writeUint8(0xdb);
      buffer.writeUint32(utf8.length);
    }
    writeAllBytes(utf8);
  }

  void packDouble(double value) {
    buffer.writeUint8(0xcb);
    var f = new ByteData(8);
    f.setFloat64(0, value);
    writeAllBytes(f);
  }

  void packFloat(Float float) {
    buffer.writeUint8(0xca);
    var f = new ByteData(4);
    f.setFloat32(0, float.value);
    writeAllBytes(f);
  }

  void packList(List value) {
    var len = value.length;
    if (len < 16) {
      buffer.writeUint8(0x90 + len);
    } else if (len < 0x100) {
      buffer.writeUint8(0xdc);
      buffer.writeUint16(len);
    } else {
      buffer.writeUint8(0xdd);
      buffer.writeUint32(len);
    }

    for (var i = 0; i < len; i++) {
      pack(value[i]);
    }
  }

  void packMap(Map value) {
    if (value.length < 16) {
      buffer.writeUint8(0x80 + value.length);
    } else if (value.length < 0x100) {
      buffer.writeUint8(0xde);
      buffer.writeUint16(value.length);
    } else {
      buffer.writeUint8(0xdf);
      buffer.writeUint32(value.length);
    }

    for (var element in value.keys) {
      pack(element);
      pack(value[element]);
    }
  }

  void writeAllBytes(list) {
    if (list is Uint8List) {
      buffer.writeUint8List(list);
    } else if (list is ByteData) {
      buffer.writeUint8List(list.buffer.asUint8List(
        list.offsetInBytes,
        list.lengthInBytes
      ));
    } else if (list is List) {
      for (var b in list) {
        buffer.writeUint8(b);
      }
    } else {
      throw new Exception("I don't know how to write everything in ${list}");
    }
  }

  Uint8List done() {
    return buffer.done();
  }
}
