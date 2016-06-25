part of msgpack;

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
    defaultValue: 256
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
    _buffers.length = 0;
    _buffer = null;
    _len = 0;
    _totalLength = 0;
    _offset = 0;
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
      writeAll(value.data);
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
    var count = data.elementSizeInBytes * data.lengthInBytes;
    var list = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    if (count <= 255) {
      buffer.writeUint8(0xc4);
      buffer.writeUint8(count);
      writeAll(list);
    } else if (count <= 65535) {
      buffer.writeUint8(0xc5);
      buffer.writeUint16(count);
      writeAll(list);
    } else {
      buffer.writeUint8(0xc6);
      buffer.writeUint32(count);
      writeAll(list);
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
    writeAll(utf8);
  }

  void packDouble(double value) {
    buffer.writeUint8(0xcb);
    var f = new ByteData(8);
    f.setFloat64(0, value);
    writeAll(f);
  }

  void packFloat(Float float) {
    buffer.writeUint8(0xca);
    var f = new ByteData(4);
    f.setFloat32(0, float.value);
    writeAll(f);
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

    for (var element in value) {
      pack(element);
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

  void writeAll(list) {
    if (list is Uint8List) {
      buffer.writeUint8List(list);
    } else if (list is ByteData) {
      for (var i = 0; i < list.lengthInBytes; i++) {
        buffer.writeUint8(list.getUint8(i));
      }
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
