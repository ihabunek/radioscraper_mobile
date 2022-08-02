import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";

const apiBase = "https://radioscraper.com";

void main() {
  runApp(const Radioscraper());
}

class Radioscraper extends StatelessWidget {
  const Radioscraper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Radioscraper",
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class Radio {
  final String slug;
  final String name;
  final int playCount;
  final Play? lastPlay;

  const Radio({required this.slug, required this.name, required this.playCount, this.lastPlay});

  factory Radio.fromJson(Map<String, dynamic> json) {
    return Radio(
      slug: json["slug"],
      name: json["name"],
      playCount: json["play_count"],
      lastPlay: json["last_play"] != null ? Play.fromJson(json["last_play"]) : null,
    );
  }
}

class Play {
  final String artist;
  final String title;
  final DateTime timestamp;

  const Play({
    required this.artist,
    required this.title,
    required this.timestamp,
  });

  factory Play.fromJson(Map<String, dynamic> json) {
    return Play(
      artist: json["artist_name"],
      title: json["title"],
      timestamp: DateTime.parse(json["timestamp"]),
    );
  }
}

Future<List<Radio>> fetchRadios() async {
  final response = await http.get(Uri.parse("$apiBase/api/radios"));

  if (response.statusCode == 200) {
    return [for (final r in jsonDecode(response.body)["radios"]) Radio.fromJson(r)];
  } else {
    throw Exception("Failed to load radios");
  }
}

class _HomePageState extends State<HomePage> {
  late Future<List<Radio>> radios;

  @override
  void initState() {
    super.initState();
    radios = fetchRadios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Radioscraper"),
      ),
      body: Center(
        child: FutureBuilder<List<Radio>>(
          future: radios,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return RadioList(radios: snapshot.data!);
            } else if (snapshot.hasError) {
              return Center(child: Text("${snapshot.error}"));
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class RadioList extends StatelessWidget {
  final List<Radio> radios;

  const RadioList({super.key, required this.radios});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(4.0),
      children: [for (final radio in radios) RadioBox(radio: radio)],
    );
  }
}

class RadioBox extends StatelessWidget {
  final Radio radio;

  const RadioBox({super.key, required this.radio});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(radio.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (radio.lastPlay != null)
            PlayWidget(play: radio.lastPlay!)
          else
            const Padding(padding: EdgeInsets.only(top: 4.0), child: Text("Nothing playing")),
        ]));
  }
}

class PlayWidget extends StatelessWidget {
  final Play play;

  const PlayWidget({super.key, required this.play});

  @override
  Widget build(BuildContext context) {
    DateFormat format = DateFormat('dd.MM.yyyy @ kk:mm');

    return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(play.artist, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text(": "),
            Text(play.title),
          ]),
          Text(format.format(play.timestamp)),
        ]));
  }
}
