part of msgpack;

abstract class PackBuffer {
  void writeUint8(int b);
  void writeUint16(int value);
  void writeUint32(int value);
  void writeUint8List(Uint8List list);

  Uint8List done();
}

class MsgPackBuffer implements PackBuffer {
  int _pos = 0;
  int _len = 0;
  Uint8List _list;
  List<Uint8List> _lists;

  @override
  void writeUint16(int value) {
    writeUint8((value >> 8) & 0xff);
    writeUint8(value & 0xff);
  }

  @override
  void writeUint32(int value) {
    writeUint8((value >> 24) & 0xff);
    writeUint8((value >> 16) & 0xff);
    writeUint8((value >> 8) & 0xff);
    writeUint8(value & 0xff);
  }

  @override
  void writeUint8(int b) {
    if (_lists == null) {
      _lists = [];
    }

    if (_list == null || _pos >= _list.length) {
      if (_list != null) {
        _lists.add(new Uint8List.view(_list.buffer, 0, _pos));
      }
      _list = new Uint8List(128);
      _pos = 0;
    }

    _list[_pos] = b;
    _pos++;
    _len++;
  }

  @override
  Uint8List done() {
    if (_list != null && _pos != 0) {
      _lists.add(new Uint8List.view(_list.buffer, 0, _pos));
      _pos = 0;
    }

    var out = new Uint8List(_len);
    var i = 0;
    for (var a in _lists) {
      for (var b in a) {
        out[i] = b;
        i++;
      }
    }
    _list = null;
    _lists = null;
    _len = 0;
    _pos = 0;
    return out;
  }

  @override
  void writeUint8List(Uint8List list) {
    for (var b in list) {
      writeUint8(b);
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
        _encodeUint64(value, true);
      }
    }
  }

  void _encodeUint64(int value, [bool isSigned = false]) {
    if (_isJavaScript && isSigned) {
      buffer.writeUint8((value ~/ 72057594037927936) & 0xff);
      buffer.writeUint8((value ~/ 281474976710656) & 0xff);
      buffer.writeUint8((value ~/ 1099511627776) & 0xff);
      buffer.writeUint8((value ~/ 4294967296) & 0xff);
    } else {
      buffer.writeUint8((value >> 56) & 0xff);
      buffer.writeUint8((value >> 48) & 0xff);
      buffer.writeUint8((value >> 40) & 0xff);
      buffer.writeUint8((value >> 32) & 0xff);
    }

    buffer.writeUint8((value >> 24) & 0xff);
    buffer.writeUint8((value >> 16) & 0xff);
    buffer.writeUint8((value >> 8) & 0xff);
    buffer.writeUint8(value & 0xff);
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
