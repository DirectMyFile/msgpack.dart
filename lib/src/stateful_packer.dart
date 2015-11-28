part of msgpack;

class StatefulPacker {
  StatefulPacker();

  void pack(value) {
    if (value is Iterable && value is! List) {
      value = value.toList();
    }

    if (value == null) {
      write(0xc0);
    } else if (value == false) {
      write(0xc2);
    } else if (value == true) {
      write(0xc3);
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

    if (count <= 255) {
      write(0xc4);
      write(count);
      writeAll(data.buffer.asUint8List());
    } else if (count <= 65535) {
      write(0xc5);
      _encodeUint16(count);
      writeAll(data.buffer.asUint8List());
    } else {
      write(0xc6);
      _encodeUint32(count);
      writeAll(data.buffer.asUint8List());
    }
  }

  void packInt(int value) {
    if (value >= 0 && value < 128) {
      write(value);
      return;
    }

    if (value < 0) {
      if (value >= -32) {
        write(0xe0 + value + 32);
      } else if (value > -0x80) {
        write(0xd0);
        write(value + 0x100);
      } else if (value > -0x8000) {
        write(0xd1);
        _encodeUint16(value + 0x10000);
      } else if (value > -0x80000000) {
        write(0xd2);
        _encodeUint32(value + 0x100000000);
      } else {
        write(0xd3);
        _encodeUint64(value);
      }
    } else {
      if (value < 0x100) {
        write(0xcc);
        write(value);
      } else if (value < 0x10000) {
        write(0xcd);
        _encodeUint16(value);
      } else if (value < 0x100000000) {
        write(0xce);
        _encodeUint32(value);
      } else {
        write(0xcf);
        _encodeUint64(value);
      }
    }
  }

  void _encodeUint16(int value) {
    write((value >> 8) & 0xff);
    write(value & 0xff);
  }

  void _encodeUint32(int value) {
    write((value >> 24) & 0xff);
    write((value >> 16) & 0xff);
    write((value >> 8) & 0xff);
    write(value & 0xff);
  }

  void _encodeUint64(int value) {
    write((value >> 56) & 0xff);
    write((value >> 48) & 0xff);
    write((value >> 40) & 0xff);
    write((value >> 32) & 0xff);
    write((value >> 24) & 0xff);
    write((value >> 16) & 0xff);
    write((value >> 8) & 0xff);
    write(value & 0xff);
  }

  static const Utf8Encoder _utf8Encoder = const Utf8Encoder();

  void packString(String value) {
    List<int> utf8;

    if (StringCache.has(value)) {
      utf8 = StringCache.get(value);
    } else {
      utf8 = _utf8Encoder.convert(value);
    }

    if (utf8.length < 0x20) {
      write(0xa0 + utf8.length);
    } else if (utf8.length < 0x100) {
      write(0xd9);
      write(utf8.length);
    } else if (utf8.length < 0x10000) {
      write(0xda);
      _encodeUint16(utf8.length);
    } else {
      write(0xdb);
      _encodeUint32(utf8.length);
    }
    writeAll(utf8);
  }

  void packDouble(double value) {
    write(0xcb);
    var f = new ByteData(8);
    f.setFloat64(0, value);
    writeAll(f);
  }

  void packFloat(Float float) {
    write(0xca);
    var f = new ByteData(4);
    f.setFloat32(0, float.value);
    writeAll(f);
  }

  void packList(List value) {
    var len = value.length;
    if (len < 16) {
      write(0x90 + len);
    } else if (len < 0x100) {
      write(0xdc);
      _encodeUint16(len);
    } else {
      write(0xdd);
      _encodeUint32(len);
    }

    for (var element in value) {
      pack(element);
    }
  }

  void packMap(Map value) {
    if (value.length < 16) {
      write(0x80 + value.length);
    } else if (value.length < 0x100) {
      write(0xde);
      _encodeUint16(value.length);
    } else {
      write(0xdf);
      _encodeUint32(value.length);
    }

    for (var element in value.keys) {
      pack(element);
      pack(value[element]);
    }
  }

  void writeAll(list) {
    if (list is ByteData) {
      for (var i = 0; i < list.lengthInBytes; i++) {
        write(list.getUint8(i));
      }
    } else if (list is List) {
      for (var b in list) {
        write(b);
      }
    } else {
      throw new Exception("I don't know how to write everything in ${list}");
    }
  }

  void write(int b) {
    if (lists == null) {
      lists = [];
    }

    if (list == null || pos >= list.length) {
      if (list != null) {
        lists.add(new Uint8List.view(list.buffer, 0, pos));
      }
      list = new Uint8List(64);
      pos = 0;
    }

    list[pos] = b;
    pos++;
    len++;
  }

  Uint8List done() {
    if (list != null) {
      lists.add(new Uint8List.view(list.buffer, 0, pos));
      pos = 0;
    }

    var out = new Uint8List(len);
    var i = 0;
    for (var a in lists) {
      for (var b in a) {
        out[i] = b;
        i++;
      }
    }
    list = null;
    lists = null;
    return out;
  }

  int pos = 0;
  int len = 0;
  Uint8List list;
  List<Uint8List> lists;
}
