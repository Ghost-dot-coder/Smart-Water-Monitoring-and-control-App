import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AutoPumpingAnalysis extends StatefulWidget {
  const AutoPumpingAnalysis({super.key});

  @override
  AutoPumpingAnalysisState createState() => AutoPumpingAnalysisState();
}

class AutoPumpingAnalysisState extends State<AutoPumpingAnalysis> {
  final String channelID = "2869949";
  final String apiKey = "S67XCMKI89F5VYLO";
  List<Map<String, String>> logs = [];
  Duration totalOnDuration = Duration.zero;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
        "https://api.thingspeak.com/channels/$channelID/feeds.json?api_key=$apiKey&results=50");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feeds = data['feeds'];

        List<Map<String, String>> newLogs = [];
        DateTime? lastOnTime;
        Duration onDuration = Duration.zero;
        double? previousLevel;

        for (var feed in feeds) {
          String rawTime = feed["created_at"];
          DateTime timestamp = DateTime.parse(rawTime).toLocal();
          String formattedTime =
              DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

          double waterLevel = double.tryParse(feed["field3"] ?? "3") ?? 0;
          String status = "UNKNOWN";

          if (previousLevel != null) {
            if (waterLevel > previousLevel) {
              status = "ON";
              lastOnTime ??= timestamp;
            } else if (waterLevel <= previousLevel && lastOnTime != null) {
              onDuration += timestamp.difference(lastOnTime);
              lastOnTime = null;
              status = "OFF";
            }
          }
          previousLevel = waterLevel;

          newLogs.add({"time": formattedTime, "status": status});
        }

        setState(() {
          logs = newLogs.reversed.toList();
          totalOnDuration = onDuration;
        });
      } else {
        throw Exception("Failed to fetch data");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Automatic Pumping Analysis")),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: Icon(
                              logs[index]['status'] == "ON"
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              color: logs[index]['status'] == "ON"
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(logs[index]['time']!),
                            subtitle: Text("Motor: ${logs[index]['status']}",
                                style: TextStyle(
                                    color: logs[index]['status'] == "ON"
                                        ? Colors.green
                                        : Colors.red)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
