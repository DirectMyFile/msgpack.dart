part of msgpack;

class StatefulPacker {
  Uint8Buffer bytes = new Uint8Buffer();

  StatefulPacker();

  void pack(value) {
    if (value is Iterable && value is! List) {
      value = value.toList();
    }

    if (value == null) {
      bytes.add(0xc0);
    } else if (value == false) {
      bytes.add(0xc2);
    } else if (value == true) {
      bytes.add(0xc3);
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
    } else if (value is ByteData) {
      packBinary(value);
    } else if (value is PackedReference) {
      bytes.addAll(value.data);
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

    if (count <= 255) {
      bytes.add(0xc4);
      bytes.add(count);
      bytes.addAll(data.buffer.asUint8List());
    } else if (count <= 65535) {
      bytes.add(0xc5);
      _encodeUint16(count);
      bytes.addAll(data.buffer.asUint8List());
    } else {
      bytes.add(0xc6);
      _encodeUint32(count);
      bytes.addAll(data.buffer.asUint8List());
    }
  }

  void packInt(int value) {
    if (value < 128) {
      bytes.add(value);
      return;
    }

    if (value < 0) {
      if (value >= -32) {
        bytes.add(0xe0 + value + 32);
      } else if (value > -0x80) {
        bytes.add(0xd0);
        bytes.add(value + 0x100);
      } else if (value > -0x8000) {
        bytes.add(0xd1);
        _encodeUint16(value + 0x10000);
      } else if (value > -0x80000000) {
        bytes.add(0xd2);
        _encodeUint32(value + 0x100000000);
      } else {
        bytes.add(0xd3);
        _encodeUint64(value);
      }
    } else {
      if (value < 0x100) {
        bytes.add(0xcc);
        bytes.add(value);
      } else if (value < 0x10000) {
        bytes.add(0xcd);
        _encodeUint16(value);
      } else if (value < 0x100000000) {
        bytes.add(0xce);
        _encodeUint32(value);
      } else {
        bytes.add(0xcf);
        _encodeUint64(value);
      }
    }
  }

  void _encodeUint16(int value) {
    bytes.add((value >> 8) & 0xff);
    bytes.add(value & 0xff);
  }

  void _encodeUint32(int value) {
    bytes.add((value >> 24) & 0xff);
    bytes.add((value >> 16) & 0xff);
    bytes.add((value >> 8) & 0xff);
    bytes.add(value & 0xff);
  }

  void _encodeUint64(int value) {
    bytes.add((value >> 56) & 0xff);
    bytes.add((value >> 48) & 0xff);
    bytes.add((value >> 40) & 0xff);
    bytes.add((value >> 32) & 0xff);
    bytes.add((value >> 24) & 0xff);
    bytes.add((value >> 16) & 0xff);
    bytes.add((value >> 8) & 0xff);
    bytes.add(value & 0xff);
  }

  static const Utf8Encoder _utf8Encoder = const Utf8Encoder();

  void packString(String value) {
    List<int> utf8 = _utf8Encoder.convert(value);
    if (utf8.length < 0x20) {
      bytes.add(0xa0 + utf8.length);
    } else if (utf8.length < 0x100) {
      bytes.add(0xd9);
      bytes.add(utf8.length);
    } else if (utf8.length < 0x10000) {
      bytes.add(0xda);
      _encodeUint16(utf8.length);
    } else {
      bytes.add(0xdb);
      _encodeUint32(utf8.length);
    }
    bytes.addAll(utf8);
  }

  void packDouble(double value) {
    var f = new ByteData(9);
    f.setUint8(0, 0xcb);
    f.setFloat64(1, value);
    bytes.addAll(f.buffer.asUint8List());
  }

  void packList(List value) {
    if (value.length < 16) {
      bytes.add(0x90 + value.length);
    } else if (value.length < 0x100) {
      bytes.add(0xdc);
      _encodeUint16(value.length);
    } else {
      bytes.add(0xdd);
      _encodeUint32(value.length);
    }

    for (var element in value) {
      pack(element);
    }
  }

  void packMap(Map value) {
    if (value.length < 16) {
      bytes.add(0x80 + value.length);
    } else if (value.length < 0x100) {
      bytes.add(0xde);
      _encodeUint16(value.length);
    } else {
      bytes.add(0xdf);
      _encodeUint32(value.length);
    }

    for (var element in value.keys) {
      pack(element);
      pack(value[element]);
    }
  }
}
