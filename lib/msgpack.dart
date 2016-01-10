library msgpack;

import "dart:convert";
import "dart:typed_data";

part "src/packer.dart";
part "src/unpacker.dart";
part "src/message.dart";
part "src/stateful_packer.dart";

/// A Cache for Common Strings
class StringCache {
  static Map<String, List<int>> _cache = {};

  static bool has(String str) {
    return _cache.containsKey(str);
  }

  static void store(String string) {
    _cache[string] = toUTF8(string);
  }

  static List<int> get(String string) {
    return _cache[string];
  }

  static void clear() {
    _cache.clear();
  }
}

Uint8List _toUTF8(String str) {
  int length = str.length;
  Uint8List bytes = new Uint8List(length);
  for (int i = 0; i < length; i++) {
    int unit = str.codeUnitAt(i);
    if (unit >= 128) {
      return new Uint8List.fromList(const Utf8Encoder().convert(str));
    }
    bytes[i] = unit;
  }
  return bytes;
}
