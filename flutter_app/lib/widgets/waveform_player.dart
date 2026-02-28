import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class WaveformPlayer extends StatefulWidget {
  final String audioPath;
  const WaveformPlayer({super.key, required this.audioPath});

  @override
  State<WaveformPlayer> createState() => _WaveformPlayerState();
}

class _WaveformPlayerState extends State<WaveformPlayer> {
  late AudioPlayer _player;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setFilePath(widget.audioPath);
    } catch (e) {
      // ignore
    }
    setState(() {});
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Placeholder for waveform rendering
        Container(
          height: 160,
          margin: const EdgeInsets.all(12),
          color: Colors.grey.shade200,
          child: const Center(child: Text('Waveform placeholder')),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              onPressed: () async {
                if (_playing) {
                  await _player.pause();
                } else {
                  await _player.play();
                }
                setState(() => _playing = !_playing);
              },
            ),
            StreamBuilder<Duration?>(
                stream: _player.durationStream,
                builder: (context, snapshot) {
                  final d = snapshot.data ?? Duration.zero;
                  return Text(d.inSeconds > 0 ? '${d.inSeconds}s' : '0s');
                })
          ],
        )
      ],
    );
  }
}
