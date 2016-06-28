import "package:msgpack/msgpack.dart";

import "dart:typed_data";
import "dart:math";

main() {
  var byteList = new Uint8List(1024 * 1024 * 50);
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
  var times = <List<int>>[];
  for (var i = 1; i <= 5; i++) {
    times.add(go(input));
  }
  watch.stop();

  var totalEncodeTime = 0;
  var totalDecodeTime = 0;
  for (var time in times) {
    totalEncodeTime += time[0];
    totalDecodeTime += time[1];
  }
  var avgEncodeTime = totalEncodeTime / times.length;
  var avgDecodeTime = totalDecodeTime / times.length;

  print("Took an average of ${(avgEncodeTime / 1000).toStringAsFixed(2)}ms to encode.");
  print("Took an average of ${(avgDecodeTime / 1000).toStringAsFixed(2)}ms to decode.");
}

List<int> go(input) {
  var out = <int>[];
  var watch = new Stopwatch();
  watch.start();
  var encoded = pack(input);
  watch.stop();
  print("Took ${watch.elapsedMicroseconds / 1000}ms to encode.");
  out.add(watch.elapsedMicroseconds);
  watch.reset();
  watch.start();
  var decoded = unpack(encoded);
  watch.stop();
  print("Took ${watch.elapsedMicroseconds / 1000}ms to decode.");
  out.add(watch.elapsedMicroseconds);
  return out;
}
