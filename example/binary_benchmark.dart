import "package:msgpack/msgpack.dart";

import "dart:typed_data";
import "dart:math";

main() {
  var byteList = new Uint8List(1024 * 1024 * 5);
  var random = new Random();
  for (var i = 0; i < byteList.lengthInBytes; i++) {
    byteList[i] = random.nextInt(255);
  }

  var byteData = byteList.buffer.asByteData(
    byteList.offsetInBytes,
    byteList.lengthInBytes
  );

  var input = {
    "responses": [
      {
        "rid": 0,
        "updates": [
          {
            "sid": 55,
            "ts": new DateTime.now().toIso8601String(),
            "value": byteData
          }
        ]
      }
    ]
  };

  for (var i = 1; i <= 5; i++) {
    var encoded = pack(input);
    unpack(encoded);
  }

  var watch = new Stopwatch();
  watch.start();
  var encoded = pack(input);
  watch.stop();
  print("Took ${watch.elapsedMicroseconds / 1000}ms to encode.");
  watch.reset();
  watch.start();
  var decoded = unpack(encoded);
  watch.stop();
  print("Took ${watch.elapsedMicroseconds / 1000}ms to decode.");
}
