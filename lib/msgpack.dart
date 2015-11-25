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
    _cache[string] = const Utf8Encoder().convert(string);
  }

  static List<int> get(String string) {
    return _cache[string];
  }

  static void clear() {
    _cache.clear();
  }
}
