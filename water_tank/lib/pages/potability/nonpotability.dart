import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class NonPotabilityScreen extends StatefulWidget {
  const NonPotabilityScreen({super.key});

  @override
  State<NonPotabilityScreen> createState() => _NonPotabilityScreenState();
}

class _NonPotabilityScreenState extends State<NonPotabilityScreen> {
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

  final String channelId = 'channel id';
  final String motorChannelId = 'channel id';
  final String objectDetectionChannelId = 'channel id';
  final String readApiKey = 'api key';
  final String motorReadApiKey = 'api key';
  final String objectDetectionReadApiKey = 'api key';
  final String writeApiKey = 'api key';
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
    Timer.periodic(Duration(seconds: 1), (timer) {
      _fetchSensorData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Potability Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.warning_rounded, // Warning icon
                    color: Colors.red,
                    size: 50,
                  ),
                  Text(
                    "Water is Non-Potable!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildQualityCard(
                    title: "pH Level",
                    optimalRange: null,
                    value: ' ${_data['pH']?.toString() ?? 'Loading...'}',
                    isInRange: _isInRange(_data['pH'], minPH, maxPH),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.water_drop_rounded,
                                  color:
                                      _isInRange(_data['tds'], minTDS, maxTDS)
                                          ? Colors.blue
                                          : Colors.red,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        'TDS',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        ' ${_data['tds']?.toString() ?? 'Loading...'}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.water_drop_rounded,
                                  color:
                                      _isInRange(_data['turbidity'], 750, 950)
                                          ? Colors.blue
                                          : Colors.red,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Turbidity',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        ' ${_data['turbidity']?.toString() ?? 'Loading...'}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "• The pH is too low, making the water highly acidic and corrosive.\n"
                          "• TDS is above the recommended limit, indicating excess dissolved solids.\n"
                          "• High turbidity suggests the presence of suspended particles, dirt, or microbes.",
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "✅ Recommended Treatment Methods:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "1️⃣ pH Correction: Add baking soda or limestone chips.\n"
                          "2️⃣ TDS Reduction: Use Reverse Osmosis (RO) filtration.\n"
                          "3️⃣ Turbidity Removal: Use sediment & activated carbon filters.\n"
                          "4️⃣ Boiling: Kills bacteria and improves temporary safety.\n"
                          "5️⃣ Chemical Disinfection: Use chlorine or UV purification.",
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildQualityCard({
    required String title,
    required String? value,
    required String? optimalRange,
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    value ?? 'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      color: isInRange ? Colors.black : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
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
