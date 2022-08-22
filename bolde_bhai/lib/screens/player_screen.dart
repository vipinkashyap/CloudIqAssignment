import 'dart:developer';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late PlayerController playerController;

  String twoDigits(int n) => n.toString().padLeft(2, "0");

  String durationLabel = "00:00";
  String twoDigitMinutes = "00";
  String twoDigitSeconds = "00";

  String durationLabelCurrent = "00:00";
  String twoDigitMinutesCurrent = "00";
  String twoDigitSecondsCurrent = "00";

  //Function to start playing
  Future startPlaying([String path = '']) async {
    if (path.isEmpty) {
      await playerController.startPlayer();
    }

    await playerController.preparePlayer(path);

    var duration = Duration(milliseconds: await playerController.getDuration());
    twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    await playerController.startPlayer();

    setState(() {});
  }

  //Function to pause playing
  Future pausePlaying() async {
    await playerController.pausePlayer();
  }

  //Function to stop playing
  Future stopPlaying() async {
    await playerController.stopPlayer();
    setState(() {});
  }

  @override
  void dispose() {
    playerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    playerController = PlayerController();
    playerController.onCurrentDurationChanged.listen((duration) {
      log('Duration: $duration');
    });
    playerController.onPlayerStateChanged.listen((playerState) {
      log('Player state: $playerState');
    });
  }

  Future<List<FileSystemEntity>> fetchTempFiles() async =>
      await getTemporaryDirectory().then((dir) => dir.listSync());

  deleteTempFile(FileSystemEntity file) {
    file.deleteSync();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: const Key('pausePlaying'),
            child: const Icon(Icons.pause),
            onPressed: () async {
              if (playerController.playerState == PlayerState.paused) {
                startPlaying();
              }
              pausePlaying();
            },
          ),
          FloatingActionButton(
            heroTag: const Key('stopPlaying'),
            child: const Icon(Icons.stop),
            onPressed: () async {
              stopPlaying();
            },
          ),
        ],
      ),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Player Screen'),
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<List<FileSystemEntity>>(
            future: fetchTempFiles(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                var data = snapshot.data!;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            return Dismissible(
                              background: Container(color: Colors.red),
                              onDismissed: (direction) async {
                                await deleteTempFile(data[index]);
                                data.removeAt(index);
                              },
                              key: Key('recording#$index'),
                              child: GestureDetector(
                                onTap: () {
                                  stopPlaying();
                                  startPlaying(data[index].path);
                                },
                                child: ListTile(
                                  leading: Text('${index + 1}'),
                                  title: Text(data[index].path.fileName()),
                                ),
                              ),
                            );
                          }),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Column(
                      children: [
                        Center(
                          child: AudioFileWaveforms(
                            key: const Key("playerWave"),
                            size:
                                Size(MediaQuery.of(context).size.width, 200.0),
                            playerController: playerController,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StreamBuilder<int>(
                                stream:
                                    playerController.onCurrentDurationChanged,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.active &&
                                      snapshot.hasData) {
                                    var _duration =
                                        Duration(milliseconds: snapshot.data!);
                                    twoDigitMinutesCurrent = twoDigits(
                                        _duration.inMinutes.remainder(60));
                                    twoDigitSecondsCurrent = twoDigits(
                                        _duration.inSeconds.remainder(60));
                                    return Text(
                                      "$twoDigitMinutesCurrent:$twoDigitSecondsCurrent",
                                      textScaleFactor: 1.0,
                                    );
                                  }
                                  return Text(
                                    "$twoDigitMinutesCurrent:$twoDigitSecondsCurrent",
                                    textScaleFactor: 1.0,
                                  );
                                }),
                            Text(
                              "$twoDigitMinutes:$twoDigitSeconds",
                              textScaleFactor: 1.0,
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            }),
      ),
    );
  }
}

extension RecordedFileTitle on String {
  String fileName() {
    return split('/').last;
  }
}
