import "dart:convert";
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
    new Float(5.38)
  ];

  List<int> packed = pack(data);
  Map unpacked = unpack(packed);

  print("Original: ${data}");
  print("Unpacked: ${unpacked}");
}
