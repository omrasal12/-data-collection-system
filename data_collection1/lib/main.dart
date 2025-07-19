// import 'package:data_collection1/data_collection_sdk.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:telephony/telephony.dart';
// import 'package:call_log/call_log.dart';


// void main() {
//   runApp(DataCollectionApp());
// }

// class DataCollectionApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Data Collector',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: DataCollectionScreen(),
//     );
//   }
// }

// class DataCollectionScreen extends StatefulWidget {
//   @override
//   _DataCollectionScreenState createState() => _DataCollectionScreenState();
// }

// class _DataCollectionScreenState extends State<DataCollectionScreen> {
//   final Telephony telephony = Telephony.instance;
//   late DataCollectionSDK sdk;

//   List<String> logs = [];
//   bool isLoading = false;
//   bool hasSmsPermission = false;
//   bool hasCallPermission = false;
//   int smsCount = 0;
//   int callCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     sdk = DataCollectionSDK(baseUrl: "http://10.0.2.2:5105");
//     _checkPermissions();
//   }

//   Future<void> _checkPermissions() async {
//     final status = await Future.wait([
//       Permission.sms.status,
//       Permission.phone.status,
//     ]);

//     setState(() {
//       hasSmsPermission = status[0].isGranted;
//       hasCallPermission = status[1].isGranted;
//     });
//   }

//   Future<void> _requestPermissions() async {
//     setState(() => isLoading = true);
//     _addLog("Requesting permissions...");

//     final status = await [
//       Permission.sms,
//       Permission.phone,
//     ].request();

//     setState(() {
//       hasSmsPermission = status[Permission.sms]!.isGranted;
//       hasCallPermission = status[Permission.phone]!.isGranted;
//       isLoading = false;
//     });

//     _addLog("Permissions granted: "
//         "SMS - ${hasSmsPermission ? 'Yes' : 'No'}, "
//         "Call - ${hasCallPermission ? 'Yes' : 'No'}");
//   }

//   Future<void> _collectData() async {
//     if (!hasSmsPermission || !hasCallPermission) {
//       _addLog("Please grant permissions first");
//       return;
//     }

//     setState(() {
//       isLoading = true;
//       smsCount = 0;
//       callCount = 0;
//     });

//     try {
//       await _processSms();
//       await _processCallLogs();
//       _addLog("Data collection completed!");
//     } catch (e) {
//       _addLog("Error: ${e.toString()}");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> _processSms() async {
//     _addLog("Reading SMS messages...");
//     try {
//       bool? permissionGranted = await telephony.requestSmsPermissions;

//       if (permissionGranted == null || !permissionGranted) {
//         _addLog("SMS permission not granted by telephony.");
//         return;
//       }

//       final messages = await telephony.getInboxSms(
//         columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
//         sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
//       );

//       _addLog("Found ${messages.length} SMS messages");

//       final batch = <Map<String, dynamic>>[];

//       for (var sms in messages) {
//         final event = {
//           'eventType': 'sms',
//           'sender': sms.address ?? 'Unknown',
//           'message': sms.body ?? '',
//           'timestamp': DateTime.fromMillisecondsSinceEpoch(sms.date ?? 0).toIso8601String(),
//           'isTransactional': sdk.isTransactional(sms.body ?? ''),
//         };

//         if (event['isTransactional'] == true) {
//           _addLog("Sending transactional SMS from ${event['sender']}");
//           await sdk.sendEvent(event);
//           setState(() => smsCount++);
//         } else {
//           batch.add(event);
//         }

//         if (batch.length >= sdk.batchSize) {
//           _addLog("Sending batch of ${batch.length} SMS");
//           await sdk.sendBatch(batch);
//           setState(() => smsCount += batch.length);
//           batch.clear();
//         }
//       }

//       if (batch.isNotEmpty) {
//         _addLog("Sending final batch of ${batch.length} SMS");
//         await sdk.sendBatch(batch);
//         setState(() => smsCount += batch.length);
//       }
//     } catch (e) {
//       _addLog("SMS processing error: $e");
//     }
//   }

//   Future<void> _processCallLogs() async {
//     _addLog("Reading call logs...");

//     try {
//       final Iterable<CallLogEntry> callLogs = await CallLog.get();
//       _addLog("Found ${callLogs.length} call logs");

//       final batch = <Map<String, dynamic>>[];

//       for (var call in callLogs) {
//         batch.add({
//           'eventType': 'call',
//           'callType': _getCallType(call.callType),
//           'phoneNumber': call.number ?? 'Unknown',
//           'timestamp': DateTime.fromMillisecondsSinceEpoch(call.timestamp ?? 0).toIso8601String(),
//           'duration': call.duration ?? 0,
//         });

//         if (batch.length >= sdk.batchSize) {
//           _addLog("Sending batch of ${batch.length} call logs");
//           await sdk.sendBatch(batch);
//           setState(() => callCount += batch.length);
//           batch.clear();
//         }
//       }

//       if (batch.isNotEmpty) {
//         _addLog("Sending final batch of ${batch.length} call logs");
//         await sdk.sendBatch(batch);
//         setState(() => callCount += batch.length);
//       }
//     } catch (e) {
//       _addLog("Call log processing error: $e");
//     }
//   }

//   String _getCallType(CallType? type) {
//     switch (type) {
//       case CallType.incoming:
//         return 'incoming';
//       case CallType.outgoing:
//         return 'outgoing';
//       case CallType.missed:
//         return 'missed';
//       case CallType.rejected:
//         return 'rejected';
//       case CallType.blocked:
//         return 'blocked';
//       default:
//         return 'unknown';
//     }
//   }

//   void _addLog(String message) {
//     final timestamp = DateTime.now().toIso8601String().substring(11, 19);
//     setState(() {
//       logs.insert(0, "[$timestamp] $message");
//       if (logs.length > 200) logs.removeLast();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Data Collector"),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _checkPermissions,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Card(
//             margin: EdgeInsets.all(8),
//             child: Padding(
//               padding: EdgeInsets.all(12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   Column(
//                     children: [
//                       Text("SMS Collected", style: TextStyle(fontSize: 12)),
//                       Text("$smsCount", style: TextStyle(fontSize: 24)),
//                     ],
//                   ),
//                   Column(
//                     children: [
//                       Text("Calls Collected", style: TextStyle(fontSize: 12)),
//                       Text("$callCount", style: TextStyle(fontSize: 24)),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           ListTile(
//             title: Text("Permissions Status"),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("SMS: ${hasSmsPermission ? "Granted" : "Denied"}"),
//                 Text("Call Logs: ${hasCallPermission ? "Granted" : "Denied"}"),
//               ],
//             ),
//           ),
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     icon: Icon(Icons.lock_open),
//                     label: Text("Request Permissions"),
//                     onPressed: _requestPermissions,
//                     style: ElevatedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     icon: isLoading
//                         ? SizedBox(
//                             width: 16,
//                             height: 16,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: Colors.white,
//                             ),
//                           )
//                         : Icon(Icons.collections_bookmark),
//                     label: Text("Collect Data"),
//                     onPressed: isLoading ? null : _collectData,
//                     style: ElevatedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Card(
//               margin: EdgeInsets.all(8),
//               child: Padding(
//                 padding: EdgeInsets.all(8),
//                 child: ListView.builder(
//                   reverse: true,
//                   itemCount: logs.length,
//                   itemBuilder: (context, index) {
//                     return Padding(
//                       padding: EdgeInsets.symmetric(vertical: 2),
//                       child: Text(
//                         logs[index],
//                         style: TextStyle(fontFamily: 'monospace', fontSize: 12),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:data_collection1/data_collection_sdk.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:call_log/call_log.dart';

void main() {
  runApp(DataCollectionApp());
}

class DataCollectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Collector',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DataCollectionScreen(),
    );
  }
}

class DataCollectionScreen extends StatefulWidget {
  @override
  _DataCollectionScreenState createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen> {
  final Telephony telephony = Telephony.instance;
  late DataCollectionSDK sdk;

  List<String> logs = [];
  bool isLoading = false;
  bool hasSmsPermission = false;
  bool hasCallPermission = false;
  int smsCount = 0;
  int callCount = 0;

  @override
  void initState() {
    super.initState();
    sdk = DataCollectionSDK(baseUrl: "http://10.0.2.2:5105");
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Future.wait([
      Permission.sms.status,
      Permission.phone.status,
    ]);

    setState(() {
      hasSmsPermission = status[0].isGranted;
      hasCallPermission = status[1].isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() => isLoading = true);
    _addLog("Requesting permissions...");

    final status = await [
      Permission.sms,
      Permission.phone,
    ].request();

    setState(() {
      hasSmsPermission = status[Permission.sms]!.isGranted;
      hasCallPermission = status[Permission.phone]!.isGranted;
      isLoading = false;
    });

    _addLog("Permissions granted: "
        "SMS - ${hasSmsPermission ? 'Yes' : 'No'}, "
        "Call - ${hasCallPermission ? 'Yes' : 'No'}");
  }

  Future<void> _collectData() async {
    if (!hasSmsPermission || !hasCallPermission) {
      _addLog("Please grant permissions first");
      return;
    }

    setState(() {
      isLoading = true;
      smsCount = 0;
      callCount = 0;
    });

    try {
      await _processSms();
      await _processCallLogs();
      _addLog("Data collection completed!");
    } catch (e) {
      _addLog("Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _processSms() async {
    _addLog("Reading SMS messages...");
    try {
      bool? permissionGranted = await telephony.requestSmsPermissions;

      if (permissionGranted == null || !permissionGranted) {
        _addLog("SMS permission not granted by telephony.");
        return;
      }

      final messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      _addLog("Found ${messages.length} SMS messages");

      final batch = <Map<String, dynamic>>[];

      for (var sms in messages) {
        final event = {
          'eventType': 'sms',
          'sender': sms.address ?? 'Unknown',
          'message': sms.body ?? '',
          'timestamp': DateTime.fromMillisecondsSinceEpoch(sms.date ?? 0).toIso8601String(),
          'isTransactional': sdk.isTransactional(sms.body ?? ''),
        };

        if (event['isTransactional'] == true) {
          _addLog("Sending transactional SMS from ${event['sender']}");
          await sdk.sendEvent(event);
          setState(() => smsCount++);
        } else {
          batch.add(event);
        }

        if (batch.length >= sdk.batchSize) {
          _addLog("Sending batch of ${batch.length} SMS");
          await sdk.sendBatch(batch);
          setState(() => smsCount += batch.length);
          batch.clear();
        }
      }

      if (batch.isNotEmpty) {
        _addLog("Sending final batch of ${batch.length} SMS");
        await sdk.sendBatch(batch);
        setState(() => smsCount += batch.length);
      }
    } catch (e) {
      _addLog("SMS processing error: $e");
    }
  }

  Future<void> _processCallLogs() async {
    _addLog("Reading call logs...");

    try {
      final Iterable<CallLogEntry> callLogs = await CallLog.get();
      _addLog("Found ${callLogs.length} call logs");

      final batch = <Map<String, dynamic>>[];

      for (var call in callLogs) {
        String callTypeStr = _getCallType(call.callType);
        String phoneNumberStr = (call.number == null || call.number!.trim().isEmpty)
            ? 'Unknown'
            : call.number!;

        batch.add({
          'eventType': 'call',
          'callType': callTypeStr,
          'phoneNumber': phoneNumberStr,
          'timestamp': DateTime.fromMillisecondsSinceEpoch(call.timestamp ?? 0).toIso8601String(),
          'duration': call.duration ?? 0,
        });

        if (batch.length >= sdk.batchSize) {
          _addLog("Sending batch of ${batch.length} call logs");
          await sdk.sendBatch(batch);
          setState(() => callCount += batch.length);
          batch.clear();
        }
      }

      if (batch.isNotEmpty) {
        _addLog("Sending final batch of ${batch.length} call logs");
        await sdk.sendBatch(batch);
        setState(() => callCount += batch.length);
      }
    } catch (e) {
      _addLog("Call log processing error: $e");
    }
  }

  String _getCallType(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return 'incoming';
      case CallType.outgoing:
        return 'outgoing';
      case CallType.missed:
        return 'missed';
      case CallType.rejected:
        return 'rejected';
      case CallType.blocked:
        return 'blocked';
      default:
        return 'unknown';
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      logs.insert(0, "[$timestamp] $message");
      if (logs.length > 200) logs.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Collector"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkPermissions,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text("SMS Collected", style: TextStyle(fontSize: 12)),
                      Text("$smsCount", style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  Column(
                    children: [
                      Text("Calls Collected", style: TextStyle(fontSize: 12)),
                      Text("$callCount", style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text("Permissions Status"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SMS: ${hasSmsPermission ? "Granted" : "Denied"}"),
                Text("Call Logs: ${hasCallPermission ? "Granted" : "Denied"}"),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.lock_open),
                    label: Text("Request Permissions"),
                    onPressed: _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.collections_bookmark),
                    label: Text("Collect Data"),
                    onPressed: isLoading ? null : _collectData,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: ListView.builder(
                  reverse: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        logs[index],
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The SDK code with fixed JSON key casing and proper field naming
