import "package:msgpack/msgpack.dart";

import "dart:typed_data";

main() async {
  var i = {
    "responses": [
      {"rid": 0, "updates": [[1, new Uint8List.fromList(
        new List.generate(3000000, (i) => i)
      ).buffer.asByteData(), "2015-11-13T14:53:12.347-08:00"]]}
    ],
    "msg": 3
  };

  var p = pack(i);
  var a = unpack(p);
  print(a);
}
