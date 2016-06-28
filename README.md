# MsgPack for Dart

A full-featured MsgPack library for Dart.

## Simple Example

```dart
import "dart:typed_data";

import "package:msgpack/msgpack.dart";

main() {
  var binary = new Uint8List.fromList(
    new List<int>.generate(40, (int i) => i)
  ).buffer.asByteData();

  var data = {
    "String": "Hello World",
    "Integer": 42,
    "Double": 45.29,
    "Integer List": [1, 2, 3],
    "Binary": binary,
    "Map": {
      1: 2,
      3: 4
    }
  };

  List<int> packed = pack(data);
  Map unpacked = unpack(packed);

  print(unpacked);
}
```
