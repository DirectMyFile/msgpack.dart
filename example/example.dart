import "package:msgpack/msgpack.dart";

main() {
  var data = {
    "String": "Hello World",
    "Integer": 42,
    "Double": 45.29,
    "Integer List": [1, 2, 3],
    "Map": {
      1: 2,
      3: 4
    },
    "Large Number": 1455232609379,
    "Negative Large Number": -1455232609379,
    "Simple Negative": -59
  };

  List<int> packed = pack(data);
  Map unpacked = unpack(packed);

  print("Original: ${data}");
  print("Unpacked: ${unpacked}");
}
