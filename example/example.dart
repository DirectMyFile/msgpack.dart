import "package:msgpack/msgpack.dart";

main() {
  var data = {
    "responses": [
      {
        "rid": 0,
        "updates": [
          [6, 21901.11328125, "2015-11-28T13:19:13.164-05:00"],
          [8, 31.844969287790363, "2015-11-28T13:19:13.164-05:00"]
        ]
      }
    ],
    "msg": 99
  };

  List<int> packed = pack(data);
  Map unpacked = unpack(packed);

  print("Original: ${data}");
  print("Unpacked: ${unpacked}");
}
