import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:water_tank/pages/potability/nonpotability.dart';
import 'package:water_tank/pages/potability/potabilityscreen.dart';
import 'package:water_tank/pages/potability/qualityreadings.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  Map<String, dynamic> _data = {};
  bool _motorStatus = false;
  String _objectDetected = '';
  final String channelId = 'cahnnel id';
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
    Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchSensorData();
    });
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
        final objectData = json.decode(objectResponse.body);
        final motorData = json.decode(motorResponse.body);

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

          _motorStatus = motorData['feeds'][0]['field1'] == '1';
          _objectDetected = objectData['feeds'][0]['field1'];
        });
      } else {
        throw Exception('Failed to load data from ThingSpeak');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> _toggleMotor(bool value) async {
    const url = 'https://api.thingspeak.com/update.json';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'api_key': 'WSKUQGJ2P1JYBGSN',
          'field1': value ? '1' : '2',
        },
      );

      final responseBody = response.body.trim();
      print('ThingSpeak Response: $responseBody');

      if (response.statusCode == 200 && responseBody != '0') {
        setState(() {
          _motorStatus = value;
        });
      } else {
        throw Exception(
            'Failed to update motor status. Response: $responseBody');
      }
    } catch (e) {
      print('Error updating motor status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 50),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: CircularProgressIndicator(
                      value:
                          (double.tryParse(_data['waterLevel'] ?? '0') ?? 0) /
                              100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  Text(
                    ' ${_data['waterLevel']?.toString() ?? 'Loading...'}'
                    '%\nWater Level',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Motor Status: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(
                    _motorStatus ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _motorStatus ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Toggle Motor'),
                value: _motorStatus,
                onChanged: _toggleMotor,
                secondary: Icon(
                  Icons.electrical_services,
                  color: _motorStatus ? Colors.green : Colors.grey,
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.6,
                  children: [
                    _buildGridButton('Object Detection', Icons.visibility,
                        _objectDetected.toString(), null, null, 0,
                        onTap: () {}),
                    _buildGridButton(
                        'Water Leak',
                        Icons.warning,
                        _data['waterLeak'] == '1'
                            ? 'Water is leaking'
                            : 'No leakage',
                        null,
                        null,
                        0,
                        onTap: () {}),
                    _buildGridButton(
                      'Quality ',
                      Icons.science,
                      'Readings',
                      ThemeData().primaryColorDark,
                      ThemeData().copyWith().primaryColorLight,
                      10,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QualityDetailsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildGridButton(
                      'Water Potability',
                      Icons.check_circle,
                      'Check',
                      ThemeData().primaryColorDark,
                      ThemeData().copyWith().primaryColorLight,
                      10,
                      onTap: () {
                        _showDialogAndNavigate(context, _data);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showDialogAndNavigate(BuildContext context, Map<String, dynamic> data) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent manual closing
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Checking Water Potability"),
        content: const Text("Please wait..."),
      );
    },
  );

  // Wait for 3 seconds, then navigate
  Future.delayed(const Duration(seconds: 3), () {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close the dialog

    // Extract sensor values
    double pH = double.tryParse(data['pH'] ?? '0') ?? 0;
    double turbidity = double.tryParse(data['turbidity'] ?? '0') ?? 0;
    double tds = double.tryParse(data['tds'] ?? '0') ?? 0;

    // Define optimal ranges
    bool isOptimal = (pH >= 6.5 && pH <= 8.5) &&
        (turbidity >= 750 && turbidity <= 950) &&
        (tds >= 50 && tds <= 500);

    // Navigate based on sensor data
    Widget nextScreen = isOptimal ? PotabilityScreen() : NonPotabilityScreen();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  });
}

Widget _buildGridButton(String label, IconData icon, String value,
    Color? buttonColor, Color? textcolor, double? elevation,
    {VoidCallback? onTap}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: buttonColor,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(5),
    ),
    onPressed: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: textcolor,
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: textcolor),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 14, color: textcolor),
        ),
      ],
    ),
  );
}

class WaterQualityPredictor {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    final model = await FirebaseModelDownloader.instance.getModel(
      "water_quality_model",
      FirebaseModelDownloadType.latestModel,
    );

    _interpreter = Interpreter.fromFile(model.file);
  }

  Future<int> predictWaterPotability(double pH, double turbidity) async {
    if (_interpreter == null) {
      await loadModel();
    }

    var input = [pH, turbidity];
    var output = List.filled(1, 0).reshape([1, 1]);

    _interpreter!.run(input, output);

    return output[0][0] > 0.5 ? 1 : 0;
  }
}
