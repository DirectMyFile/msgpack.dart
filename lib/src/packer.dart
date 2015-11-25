part of msgpack;

List<int> pack(value, {bool stateful: false}) {
  if (stateful) {
    var packer = new StatefulPacker();
    packer.pack(value);
    return packer.done();
  } else {
    return const Packer().pack(value);
  }
}

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
    } else if (input is List) {
      return new Uint8List.fromList(input).buffer.asByteData();
    } else if (input is String) {
      var encoded = const Utf8Encoder().convert(input);
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

class Packer {
  const Packer();

  List<int> pack(value) {
    if (value == null) return const [0xc0];
    else if (value == false) return const [0xc2];
    else if (value == true) return const [0xc3];
    else if (value is int) return packInt(value);
    else if (value is String) return packString(value);
    else if (value is List) return packList(value);
    else if (value is Iterable) return packList(value is List ? value : value.toList());
    else if (value is Map) return packMap(value);
    else if (value is double) return packDouble(value);
    else if (value is ByteData) return packBinary(value);
    else if (value is Message) return packMessage(value);
    else if (value is PackedReference) return value.data;
    else if (value is Float) return packFloat(value.value);
    throw new Exception("Failed to pack value: ${value}");
  }

  List<int> packAll(values) {
    List<int> encoded = [];
    for (var value in values)
      encoded.addAll(pack(value));
    return encoded;
  }

  List<int> packMessage(Message value) {
    return packList(value.toList());
  }

  List<int> packBinary(ByteData bytes) {
    var count = bytes.elementSizeInBytes * bytes.lengthInBytes;

    if (count <= 255) {
      var out = new ByteData(count + 2);
      out.setUint8(0, 0xc4);
      out.setUint8(1, count);
      var i = 2;
      for (var a = 0; a < count; a++) {
        out.setUint8(i, bytes.getUint8(a));
        i++;
      }
      return out.buffer.asUint8List();
    } else if (count <= 65535) {
      var out = new ByteData(count + 3);
      out.setUint8(0, 0xc5);
      out.setUint16(1, count);
      var i = 3;
      for (var a = 0; a < count; a++) {
        out.setUint8(i, bytes.getUint8(a));
        i++;
      }
      return out.buffer.asUint8List();
    } else {
      var out = new ByteData(count + 5);
      out.setUint8(0, 0xc6);
      out.setUint32(1, count);
      var i = 5;
      for (var a = 0; a < count; a++) {
        out.setUint8(i, bytes.getUint8(a));
        i++;
      }
      return out.buffer.asUint8List();
    }
  }

  List<int> packInt(int value) {
    if (value >= 0 && value < 128) {
      var list = new Uint8List(1);
      list[0] = value;
      return list;
    }

    Uint8List list;

    if (value < 0) {
      if (value >= -32) {
        list = new Uint8List(1);
        list[0] = 0xe0 + value + 32;
      } else if (value > -0x80) {
        list = new Uint8List(2);
        list[0] = 0xd0;
        list[1] = value + 0x100;
      } else if (value > -0x8000) {
        list = new Uint8List(3);
        _encodeUint16(value + 0x10000, list, 1);
      } else if (value > -0x80000000) {
        list = new Uint8List(5);
        list[0] = 0xd2;
        _encodeUint32(value + 0x100000000, list, 1);
      } else {
        list = new Uint8List(9);
        list[0] = 0xd3;
        _encodeUint64(value, list, 1);
      }
    } else {
      if (value < 0x100) {
        list = new Uint8List(2);
        list[0] = 0xcc;
        list[1] = value;
      } else if (value < 0x10000) {
        list = new Uint8List(3);
        list[0] = 0xcd;
        _encodeUint16(value, list, 1);
      } else if (value < 0x100000000) {
        list = new Uint8List(5);
        list[0] = 0xce;
        _encodeUint32(value, list, 1);
      } else {
        list = new Uint8List(9);
        list[0] = 0xcf;
        _encodeUint64(value, list, 1);
      }
    }

    return list;
  }

  List<int> _encodeUint16(int value, [Uint8List bytes, int offset = 0]) {
    if (bytes == null) bytes = new Uint8List(2);
    bytes[offset] = (value >> 8) & 0xff;
    bytes[offset + 1] = value & 0xff;
    return bytes;
  }

  Uint8List _encodeUint32(int value, [Uint8List bytes, int offset = 0]) {
    if (bytes == null) bytes = new Uint8List(4);
    bytes[offset] = (value >> 24) & 0xff;
    bytes[offset + 1] = (value >> 16) & 0xff;
    bytes[offset + 2] = (value >> 8) & 0xff;
    bytes[offset + 3] = value & 0xff;
    return bytes;
  }

  List<int> _encodeUint64(int value, [Uint8List bytes, int offset = 0]) {
    if (bytes == null) bytes = new Uint8List(8);
    bytes[offset] = (value >> 56) & 0xff;
    bytes[offset + 1] = (value >> 48) & 0xff;
    bytes[offset + 2] = (value >> 40) & 0xff;
    bytes[offset + 3] = (value >> 32) & 0xff;
    bytes[offset + 4] = (value >> 24) & 0xff;
    bytes[offset + 5] = (value >> 16) & 0xff;
    bytes[offset+ 6] = (value >> 8) & 0xff;
    bytes[offset + 7] = value & 0xff;
    return bytes;
  }

  static const Utf8Encoder _utf8Encoder = const Utf8Encoder();

  List<int> packString(String value) {
    List<int> encoded = [];
    List<int> utf8 = _utf8Encoder.convert(value);
    if (utf8.length < 32) encoded.add(0xa0 | utf8.length);
    else if (utf8.length < 256) encoded.addAll([0xd9, utf8.length]);
    else if (utf8.length < 65536) encoded
      ..add(0xda)
      ..addAll(_encodeUint16(utf8.length));
    else encoded
        ..add(0xdb)
        ..addAll(_encodeUint32(utf8.length));
    encoded.addAll(utf8);
    return encoded;
  }

  List<int> packFloat(double value) {
    var f = new ByteData(4);
    f.setFloat32(0, value);
    return [0xca]..addAll(f.buffer.asUint8List());
  }

  List<int> packDouble(double value) {
    var f = new ByteData(8);
    f.setFloat64(0, value);
    return [0xcb]..addAll(f.buffer.asUint8List());
  }

  List<int> packList(List value) {
    List<int> encoded = [];
    if (value.length < 16) encoded.add(0x90 + value.length);
    else if (value.length < 0x100) encoded
      ..add(0xdc)
      ..addAll(_encodeUint16(value.length));
    else encoded
        ..add(0xdd)
        ..addAll(_encodeUint32(value.length));
    for (var element in value) {
      encoded.addAll(pack(element));
    }
    return encoded;
  }

  List<int> packMap(Map value) {
    var encoded = <int>[];
    if (value.length < 16) encoded.add(0x80 + value.length);
    else if (value.length < 0x100) encoded
      ..add(0xde)
      ..addAll(_encodeUint16(value.length));
    else encoded
        ..add(0xdf)
        ..addAll(_encodeUint32(value.length));
    for (var element in value.keys) {
      encoded.addAll(pack(element));
      encoded.addAll(pack(value[element]));
    }
    return encoded;
  }
}
