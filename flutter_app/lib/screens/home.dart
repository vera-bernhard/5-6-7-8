import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import '../widgets/waveform_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/marker_provider.dart';
import '../models/marker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AudioPlayer _player;

  String? _audioPath;
  Uint8List? _audioBytes;
  String? _audioFileName;
  String? _loadError;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  int _defaultLeadInSec = 0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
    _player.durationStream.listen((duration) {
      if (!mounted || duration == null) return;
      setState(() => _duration = duration);
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform
          .pickFiles(
            type: FileType.audio,
            withData: kIsWeb,
            withReadStream: kIsWeb,
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Audio picker timed out. Please try again.')),
        );
      }
      return;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Audio picker failed. Please try again.')),
        );
      }
      return;
    }

    if (result == null) {
      return;
    }

    if (result.files.isNotEmpty) {
      try {
        final file = result.files.first;
        final safePath = kIsWeb ? null : file.path;
        Uint8List? bytes = file.bytes;

        // On web, some browsers/plugins provide a stream but no immediate bytes.
        if (bytes == null && file.readStream != null) {
          bytes = await _readBytesFromStream(file.readStream!);
        }

        if (safePath == null && bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Could not read the selected audio file.')),
            );
          }
          return;
        }

        await _loadAudio(
          filePath: safePath,
          fileBytes: bytes,
          fileName: file.name,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not process the selected file.')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Picker returned no files. Try another browser or file.'),
          ),
        );
      }
    }
  }

  Future<Uint8List> _readBytesFromStream(Stream<List<int>> stream) async {
    final chunks = <int>[];
    try {
      await for (final chunk in stream.timeout(const Duration(seconds: 20))) {
        chunks.addAll(chunk);
      }
    } on TimeoutException {
      rethrow;
    }
    return Uint8List.fromList(chunks);
  }

  Future<void> _loadAudio({
    required String? filePath,
    required Uint8List? fileBytes,
    required String fileName,
  }) async {
    setState(() {
      _loadError = null;
      _audioPath = filePath;
      _audioBytes = fileBytes;
      _audioFileName = fileName;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;
    });

    try {
      await _player.stop();
      if (kIsWeb) {
        if (filePath != null &&
            (filePath.startsWith('blob:') ||
                filePath.startsWith('data:') ||
                filePath.startsWith('http'))) {
          await _player.setUrl(filePath);
        } else if (fileBytes != null) {
          final source = AudioSource.uri(
            Uri.dataFromBytes(
              fileBytes,
              mimeType: _mimeTypeFromFileName(fileName),
            ),
          );
          await _player.setAudioSource(source);
        } else {
          throw StateError('No browser-loadable audio source was provided.');
        }
      } else if (filePath != null) {
        await _player.setFilePath(filePath);
      } else if (fileBytes != null) {
        final source = AudioSource.uri(
          Uri.dataFromBytes(
            fileBytes,
            mimeType: _mimeTypeFromFileName(fileName),
          ),
        );
        await _player.setAudioSource(source);
      } else {
        throw StateError('No path or bytes for selected audio file.');
      }
    } catch (_) {
      setState(() {
        _loadError = 'Could not load "$fileName".';
      });
    }
  }

  String _mimeTypeFromFileName(String? fileName) {
    final lower = (fileName ?? '').toLowerCase();
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    return 'application/octet-stream';
  }

  Future<void> _onPlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _onSeek(Duration target) async {
    await _player.seek(target);
  }

  Future<void> _addMarkerAtCurrentTime() async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Name This Timestamp'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Chorus start',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (label == null) return;
    ref.read(markerListProvider.notifier).addMarker(
          _position.inMilliseconds / 1000,
          label: label,
        );
  }

  Future<void> _jumpToMarker(Marker marker,
      {required int leadInSeconds}) async {
    final startSeconds =
        math.max(0.0, marker.seconds - leadInSeconds.toDouble());
    await _player.seek(Duration(milliseconds: (startSeconds * 1000).round()));
    await _player.play();
  }

  Future<void> _showLeadInOptionsAndPlay(Marker marker) async {
    final selectedLeadIn = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start exactly at timestamp (0s lead-in)'),
                onTap: () => Navigator.of(context).pop(0),
              ),
              ListTile(
                title: const Text('Start 3 seconds before'),
                onTap: () => Navigator.of(context).pop(3),
              ),
              ListTile(
                title: const Text('Start 5 seconds before'),
                onTap: () => Navigator.of(context).pop(5),
              ),
            ],
          ),
        );
      },
    );

    if (selectedLeadIn == null) return;
    await _jumpToMarker(marker, leadInSeconds: selectedLeadIn);
  }

  String _formatSeconds(double s) {
    final total = s.round();
    final m = total ~/ 60;
    final sec = total % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final markers = ref.watch(markerListProvider);
    final sortedMarkers = [...markers]
      ..sort((a, b) => a.seconds.compareTo(b.seconds));
    final hasAudio =
        (_audioPath != null || _audioBytes != null) && _loadError == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Timestamp Trainer')),
      body: Column(
        children: [
          Expanded(
            child: hasAudio
                ? WaveformPlayer(
                    position: _position,
                    duration: _duration,
                    isPlaying: _isPlaying,
                    enabled: true,
                    fileName: _audioFileName,
                    onPlayPause: _onPlayPause,
                    onAddMarker: _addMarkerAtCurrentTime,
                    onSeek: _onSeek,
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _loadError ??
                            'No audio selected. Tap the folder button to upload an audio file.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                const Text('Default jump lead-in:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _defaultLeadInSec,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('0s')),
                    DropdownMenuItem(value: 3, child: Text('3s')),
                    DropdownMenuItem(value: 5, child: Text('5s')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _defaultLeadInSec = value);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: sortedMarkers.isEmpty
                ? const Center(
                    child: Text(
                        'No timestamps yet. Add one while the music plays.'))
                : ListView.builder(
                    itemCount: sortedMarkers.length,
                    itemBuilder: (context, i) {
                      final m = sortedMarkers[i];
                      return ListTile(
                        title: Text(
                            m.label.isEmpty ? 'Timestamp ${i + 1}' : m.label),
                        subtitle: Text('At ${_formatSeconds(m.seconds)}'),
                        onTap: hasAudio
                            ? () => _jumpToMarker(m,
                                leadInSeconds: _defaultLeadInSec)
                            : null,
                        onLongPress: hasAudio
                            ? () => _showLeadInOptionsAndPlay(m)
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => ref
                              .read(markerListProvider.notifier)
                              .removeMarker(m.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'pick',
            onPressed: _pickAudio,
            child: const Icon(Icons.folder_open),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: hasAudio ? _addMarkerAtCurrentTime : null,
            child: const Icon(Icons.add_location),
          ),
        ],
      ),
    );
  }
}
