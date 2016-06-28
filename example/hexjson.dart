import "package:msgpack/msgpack.dart";

import "dart:io";
import "dart:convert";
import "dart:typed_data";

import "package:crypto/crypto.dart";

main() async {
  var string = await stdin.transform(const Utf8Decoder()).join();
  var hexBytes = string.split(" ").where((s) => s.trim().isNotEmpty).map((s) {
    return int.parse(s, radix: 16);
  }).toList();

  var data = unpack(hexBytes);
  var encoder = new JsonEncoder((e) {
    if (e is Float) {
      return e.value;
    } else if (e is ByteData) {
      return CryptoUtils.bytesToBase64(
        e.buffer.asUint8List(e.offsetInBytes, e.lengthInBytes)
      );
    } else {
      return e;
    }
  });

  print(encoder.convert(data));
}
