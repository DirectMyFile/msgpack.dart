import "package:msgpack/msgpack.dart";

import "dart:io";

main() {
  var data = {
    "rid": 0,
    "updates": [
      [
        0,
        15,
        "2014-11-27T09:11.000-08:00"
      ]
    ]
  };

  while (true) {
    pack(data);
    sleep(const Duration(milliseconds: 1));
  }
}
