import 'dart:developer';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:bolde_bhai/screens/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path_provider/path_provider.dart';

extension JiffyFormat on DateTime {
  fmtDate() {
    final jiffyObj = Jiffy(this);
    return '${jiffyObj.year}_${jiffyObj.month}_${jiffyObj.day}_${jiffyObj.hour}_${jiffyObj.minute}_${jiffyObj.second}';
  }
}

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({Key? key}) : super(key: key);

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late final RecorderController recorderController;

  @override
  void initState() {
    super.initState();
    recorderController = RecorderController()
      ..updateFrequency = const Duration(milliseconds: 100)
      ..normalizationFactor = Platform.isAndroid ? 60 : 40;
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
  }

  Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

  String fmtDate(DateTime dateTime) {
    var jiffyObj = Jiffy(dateTime);
    return jiffyObj.yMMMMEEEEdjm;
  }

  //Function to start recording
  Future startRecording() async {
    final formattedDate = DateTime.now().fmtDate();
    final tmpPath = await getTempDirectory();
    final fileName = '${tmpPath.path}/$formattedDate';
    log(fileName);

    await recorderController.record('$fileName.aac');
  }

  //Function to pause recording
  Future pauseRecording() async {
    await recorderController.pause();
  }

  //Function to stop recording
  Future stopRecording() async {
    final path = await recorderController.stop();

    return path!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: const Key('startRecording'),
            child: const Icon(Icons.mic),
            onPressed: () {
              startRecording();
            },
          ),
          FloatingActionButton(
            heroTag: const Key('pauseRecording'),
            child: const Icon(Icons.pause),
            onPressed: () {
              pauseRecording();
            },
          ),
          FloatingActionButton(
            heroTag: const Key('stopRecording'),
            child: const Icon(Icons.stop),
            onPressed: () {
              stopRecording();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()));
            },
          ),
        ],
      ),
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()));
              },
              icon: const Icon(Icons.navigation))
        ],
        centerTitle: true,
        title: const Text('Recording Screen'),
      ),
      body: Center(
        child: AudioWaveforms(
          waveStyle: const WaveStyle(
            // waveColor: Colors.white,
            showDurationLabel: true,
            spacing: 8.0,
            extendWaveform: true,
            showMiddleLine: false,
          ),
          size: Size(MediaQuery.of(context).size.width, 200.0),
          recorderController: recorderController,
        ),
      ),
    );
  }
}
