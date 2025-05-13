import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ManualAnalysis extends StatefulWidget {
  const ManualAnalysis({super.key});

  @override
  ManualAnalysisState createState() => ManualAnalysisState();
}

class ManualAnalysisState extends State<ManualAnalysis> {
  final String channelID = "channel id";
  final String apiKey = "api key";
  List<Map<String, String>> motorLogs = [];
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

        List<Map<String, String>> logs = [];
        DateTime? lastOnTime;
        Duration onDuration = Duration.zero;

        for (var feed in feeds) {
          String rawTime = feed["created_at"];
          DateTime timestamp = DateTime.parse(rawTime).toLocal();
          String formattedTime =
              DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

          String status = feed["field1"] ?? "2";

          if (status == "1") {
            lastOnTime ??= timestamp;
          } else if (status == "2" && lastOnTime != null) {
            onDuration += timestamp.difference(lastOnTime);
            lastOnTime = null;
          }

          logs.add(
              {"time": formattedTime, "status": status == "1" ? "ON" : "OFF"});
        }

        setState(() {
          motorLogs = logs.reversed.toList(); // Latest first
          totalOnDuration = onDuration;
        });
      } else {
        throw Exception("Failed to fetch data");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: motorLogs.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: Icon(
                              motorLogs[index]['status'] == "ON"
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              color: motorLogs[index]['status'] == "ON"
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(motorLogs[index]['time']!),
                            subtitle: Text(
                                "Motor: ${motorLogs[index]['status']}",
                                style: TextStyle(
                                    color: motorLogs[index]['status'] == "ON"
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
