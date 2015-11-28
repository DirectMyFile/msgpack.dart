import "package:msgpack/msgpack.dart";

main() {
  var data = [
    53.43750000000001,
    5883939484804398999,
    "unpacked",
    5993939,
    5.48384888,
    5.5,
    -45,
    -500,
    -482858587484,
    -64000,
    new Float(5.38),
    {}
  ];

  StringCache.store("rid");
  StringCache.store("responses");
  StringCache.store("requests");
  StringCache.store("updates");

  var i = 0;
  var watch = new Stopwatch();
  var counts = [];
  while (true) {
    watch.start();
    var out = pack(data, stateful: true);
    print(unpack(out));
    watch.stop();
    counts.add(watch.elapsedMicroseconds);
    watch.reset();

    i++;

    if (i == 500) {
      break;
    }
  }

  var avg = counts.reduce((a, b) => a + b) / counts.length;
  print("Average Time: ${avg} microseconds");
}
