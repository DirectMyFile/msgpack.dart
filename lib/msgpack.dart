library msgpack;

import "dart:convert";
import "dart:typed_data";

part "src/packer.dart";
part "src/unpacker.dart";
part "src/message.dart";
part "src/stateful_packer.dart";

class _MsgPack {
  static const bool STATEFUL_WRITE_ALL_RECURSE = false;
}
