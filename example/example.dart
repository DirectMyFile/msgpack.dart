import "dart:typed_data";

import "package:msgpack/msgpack.dart";

main() {
  var binary = new Uint8List.fromList(
      new List<int>.generate(40, (int i) => i)
  ).buffer.asByteData();

  var dataC = {
    "ack": 60,
    "responses": [
      {
        "rid": 0,
        "updates": [
          [
            1,
            53.43750000000001,
            "2015-11-17T02:12:52.268Z"
          ]
        ]
      },
      {
        "rid": 4,
        "stream": "open",
        "updates": [
          [
           r"is",
            "node"
          ],
          [
            "Poll_Rate",
            {
             r"is": "node",
             r"type": "number",
             r"name": "Poll Rate",
             r"writable": "write"
            }
          ],
          [
            "Platform",
            {
             r"is": "node",
             r"type": "string"
            }
          ],
          [
            "Processor_Count",
            {
             r"is": "node",
             r"type": "number",
             r"name": "Processor Count"
            }
          ],
          [
            "Processes",
            {
             r"is": "node",
             r"type": "int",
             r"name": "Processes"
            }
          ],
          [
            "Operating_System",
            {
             r"is": "node",
             r"type": "string",
             r"name": "Operating System"
            }
          ],
          [
            "CPU_Usage",
            {
             r"is": "node",
             r"type": "number",
             r"name": "CPU Usage"
            }
          ],
          [
            "Memory_Usage",
            {
             r"is": "node",
             r"type": "number",
             r"name": "Memory Usage"
            }
          ],
          [
            "Total_Memory",
            {
             r"is": "node",
             r"type": "number",
             r"name": "Total Memory"
            }
          ],
          [
            "System_Time",
            {
             r"is": "node",
             r"type": "string",
             r"name": "System Time"
            }
          ],
          [
            "Free_Memory",
            {
             r"is": "node",
             r"type": "number",
             r"name": "Free Memory"
            }
          ],
          [
            "Used_Memory",
            {
             r"is": "node",
             r"type": "number",
             r"name": "Used Memory"
            }
          ],
          [
            "Disk_Usage",
            {
             r"is": "node",
             r"type": "number",
             r"name": "Disk Usage"
            }
          ],
          [
            "Total_Disk_Space",
            {
             r"is": "node",
             r"type": "number",
             r"name": "Total Disk Space"
            }
          ],
          [
            "Used_Disk_Space",
            {
             r"is": "node",
             r"type": "number",
             r"name": "Used Disk Space"
            }
          ],
          [
            "Free_Disk_Space",
            {
             r"is": "node",
             r"type": "number",
             r"name": "Free Disk Space"
            }
          ],
          [
            "Architecture",
            {
             r"is": "node",
             r"type": "string"
            }
          ],
          [
            "Hostname",
            {
             r"is": "node",
             r"type": "string"
            }
          ],
          [
            "Execute_Command",
            {
             r"is": "executeCommand",
             r"name": "Execute Command",
             r"invokable": "write"
            }
          ],
          [
            "Execute_Command_Stream",
            {
             r"is": "executeCommandStream",
             r"name": "Execute Command Stream",
             r"invokable": "write"
            }
          ],
          [
            "Processor_Model",
            {
             r"is": "node",
             r"type": "string",
             r"name": "Processor Model"
            }
          ],
          [
            "Open_Files",
            {
             r"is": "node",
             r"type": "int",
             r"name": "Open Files"
            }
          ]
        ]
      }
    ],
    "msg": 57
  };

  List<int> packed = pack(dataC);
  Map unpacked = unpack(packed);

  print(unpacked);
}
