
import 'dart:convert';
import 'package:http/http.dart' as http;

class DataCollectionSDK {
  final String baseUrl;
  final int batchSize;

  DataCollectionSDK({
    required this.baseUrl,
    this.batchSize = 20,
  });

  /// Determine if SMS is transactional
  bool isTransactional(String message) {
    final keywords = [
      'OTP', 'transaction', 'debited', 'credited',
      'spent', 'bank', 'payment', 'alert', 'withdraw', 'deposit'
    ];
    final lowerMessage = message.toLowerCase();
    return keywords.any((word) => lowerMessage.contains(word.toLowerCase()));
  }

  /// Send a single event (SMS or Call)
  Future<bool> sendEvent(Map<String, dynamic> event) async {
    try {
      final endpoint = event['EventType'] == 'sms'
          ? '/v1/events/sms'
          : '/v1/events/call';

      final payload = _formatEvent(event);

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send event: ${response.statusCode} - ${response.body}');
      }

      return true;
    } catch (e) {
      throw Exception('Error sending event: $e');
    }
  }

  /// Send a batch of events
  Future<bool> sendBatch(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return true;

    final formattedEvents = events.map(_formatEvent).toList();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/events/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Events': formattedEvents}), // PascalCase key 'Events'
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send batch: ${response.statusCode} - ${response.body}');
      }

      return true;
    } catch (e) {
      throw Exception('Error sending batch: $e');
    }
  }

  /// Format event based on type with PascalCase keys
  Map<String, dynamic> _formatEvent(Map<String, dynamic> event) {
    if ((event['eventType'] ?? event['EventType']) == 'sms') {
      return {
        'EventType': 'sms',
        'Sender': event['sender'] ?? event['Sender'],
        'Message': event['message'] ?? event['Message'],
        'Timestamp': event['timestamp'] ?? event['Timestamp'],
        'IsTransactional': event['isTransactional'] ?? event['IsTransactional'],
      };
    } else if ((event['eventType'] ?? event['EventType']) == 'call') {
      return {
        'EventType': 'call',
        'CallType': event['callType'] ?? event['CallType'],
        'PhoneNumber': event['phoneNumber'] ?? event['PhoneNumber'],
        'Duration': event['duration'] ?? event['Duration'],
        'Timestamp': event['timestamp'] ?? event['Timestamp'],
      };
    } else {
      throw Exception('Unknown eventType: ${event['eventType']}');
    }
  }
}