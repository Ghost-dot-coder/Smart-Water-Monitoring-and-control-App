import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class QualityDetailsScreen extends StatefulWidget {
  const QualityDetailsScreen({super.key});
  @override
  State<QualityDetailsScreen> createState() => _QualityDetailsScreenState();
}

class _QualityDetailsScreenState extends State<QualityDetailsScreen> {
  // NTU
  String? pH;
  String? tds;
  String? turbidity;
  bool isLoading = true;

  // Define optimal ranges
  static const double minPH = 6.5;
  static const double maxPH = 8.5;
  static const double minTDS = 50;
  static const double maxTDS = 500;
  // static const double maxTurbidity = 5; // NTU
  Map<String, dynamic> _data = {};

  final String channelId = '2869949';
  final String motorChannelId = '2870066';
  final String objectDetectionChannelId = '2870176';
  final String readApiKey = 'S67XCMKI89F5VYLO';
  final String motorReadApiKey = 'P13S019FE0UUHFFH';
  final String objectDetectionReadApiKey = 'UIKH1PJHP99SV3KP';
  final String writeApiKey = 'YFMDIP4GH8TQVFUN';
  @override
  void initState() {
    super.initState();
    _fetchSensorData();
    _startAutoRefresh();
  }

  Future<void> _fetchSensorData() async {
    final url =
        'https://api.thingspeak.com/channels/$channelId/feeds.json?api_key=$readApiKey&results=1';
    final objectDetectionUrl =
        'https://api.thingspeak.com/channels/$objectDetectionChannelId/feeds.json?api_key=$objectDetectionReadApiKey&results=1';
    final motorUrl =
        'https://api.thingspeak.com/channels/$motorChannelId/feeds.json?api_key=$motorReadApiKey&results=1';

    try {
      final response = await http.get(Uri.parse(url));
      final objectResponse = await http.get(Uri.parse(objectDetectionUrl));
      final motorResponse = await http.get(Uri.parse(motorUrl));

      if (response.statusCode == 200 &&
          objectResponse.statusCode == 200 &&
          motorResponse.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract the raw voltage value from field2
        double V = double.tryParse(data['feeds'][0]['field2'] ?? '0') ?? 0;

        // Apply the equation to calculate NTU
        double ntu = V;
        //-1120.4 * (V * V) + 5742.3 * V - 4352.9;

        setState(() {
          _data = {
            'pH': data['feeds'][0]['field1'],
            'turbidity': ntu.toString(),
            'waterLevel': data['feeds'][0]['field3'],
            'tds': data['feeds'][0]['field4'],
            "waterLeak": data['feeds'][0]['field5'],
          };
        });
      } else {
        throw Exception('Failed to load data from ThingSpeak');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  // Automatically refresh data every 10 seconds
  void _startAutoRefresh() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchSensorData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Water Quality Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildQualityCard(
              title: "pH Level",
              value: ' ${_data['pH']?.toString() ?? 'Loading...'}',
              optimalRange: "6.5 - 8.5",
              isInRange: _isInRange(_data['pH'], minPH, maxPH),
            ),
            buildQualityCard(
              title: "TDS (Total Dissolved Solids)",
              value: ' ${_data['tds']?.toString() ?? 'Loading...'}',
              optimalRange: "50 - 500",
              isInRange: _isInRange(_data['tds'], minTDS, maxTDS),
            ),
            buildQualityCard(
              title: "Turbidity",
              value: ' ${_data['turbidity']?.toString() ?? 'Loading...'}',
              optimalRange: "750 - 950",
              isInRange: _isInRange(_data['turbidity'], 750, 950),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQualityCard({
    required String title,
    required String? value,
    required String optimalRange,
    required bool isInRange,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.water_drop,
              color: isInRange ? Colors.blue : Colors.red,
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Measured: ${value ?? 'Loading...'}",
                    style: TextStyle(
                      fontSize: 16,
                      color: isInRange ? Colors.black : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Optimal: $optimalRange",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isInRange(String? value, double min, double max) {
    if (value == null) return true;
    final double? val = double.tryParse(value);
    return val != null && val >= min && val <= max;
  }

  // bool _isBelowThreshold(String? value, double max) {
  //   if (value == null) return true;
  //   final double? val = double.tryParse(value);
  //   return val != null && val <= max;
  // }
}
