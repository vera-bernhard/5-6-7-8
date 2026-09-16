import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import '../widgets/waveform_player.dart';
import '../models/timestamp.dart';
import '../services/song_storage.dart';

enum _HomeTab { library, player }

class _SegmentRange {
  final double start;
  final double end;
  _SegmentRange(this.start, this.end);
}

class _ShuffleSegmentSelection {
  final Timestamp startTimestamp;
  final double stopAt;
  final Set<String> timestampIds;

  _ShuffleSegmentSelection({
    required this.startTimestamp,
    required this.stopAt,
    required this.timestampIds,
  });
}

class _SongEntry {
  final String id;
  final String name;
  final Uint8List? bytes;
  final String? audioFileName;
  final List<Timestamp> timestamps;

  _SongEntry({
    required this.id,
    required this.name,
    this.bytes,
    this.audioFileName,
    List<Timestamp>? timestamps,
  }) : timestamps = timestamps ?? <Timestamp>[];
}

class _TimestampDialogResult {
  final String label;
  final double seconds;

  _TimestampDialogResult({required this.label, required this.seconds});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AudioPlayer _player;
  static const List<String> _iosAudioExtensions = <String>[
    'aac',
    'm4a',
    'mid',
    'midi',
    'mp3',
    'ogg',
    'wav',
  ];
  static const Set<String> _supportedAudioExtensions = <String>{
    'aac',
    'm4a',
    'mid',
    'midi',
    'mp3',
    'ogg',
    'wav',
  };
  static const List<int> _leadInSecondOptions = <int>[0, 1, 3, 5, 8, 15];
  static const List<int> _leadOutSecondOptions = <int>[0, 1, 3, 5, 8, 15];
  static const double _minPlaybackSpeed = 0.8;
  static const double _maxPlaybackSpeed = 1.2;
  static const List<double> _speedSnapPoints = <double>[0.95, 1.0, 1.05];
  static const double _speedSnapThreshold = 0.015;

  final List<_SongEntry> _songs = <_SongEntry>[];
  String? _activeSongId;
  _HomeTab _activeTab = _HomeTab.library;

  String? _loadError;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  int _selectedLeadInSeconds = 0;
  int _selectedLeadOutSeconds = 3;
  double _selectedPlaybackSpeed = 1.0;
  bool _isPreparingUpload = false;

  bool _segmentStopping = false;
  double? _playbackStopAtSeconds;
  int _segmentStopToken = 0;

  final Set<String> _segmentTimestampIds = {};
  final Map<String, Set<String>> _shuffleTimestampIdsBySong = {};
  final Map<String, Set<String>> _playedShuffleTimestampIdsBySong = {};

  _SongEntry? get _activeSong {
    if (_activeSongId == null) return null;
    for (final s in _songs) {
      if (s.id == _activeSongId) return s;
    }
    return null;
  }

  Set<String> _shuffleIdsForSong(String songId) {
    return _shuffleTimestampIdsBySong.putIfAbsent(songId, () => <String>{});
  }

  Set<String> _playedShuffleIdsForSong(String songId) {
    return _playedShuffleTimestampIdsBySong.putIfAbsent(
      songId,
      () => <String>{},
    );
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    unawaited(_player.setSpeed(_selectedPlaybackSpeed));
    _loadSavedSongs();
    _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
      final stopAt = _playbackStopAtSeconds;
      if (stopAt != null && _isPlaying && !_segmentStopping) {
        final currentSec = position.inMilliseconds / 1000.0;
        if (currentSec >= stopAt) {
          final stopToken = ++_segmentStopToken;
          _segmentStopping = true;
          _player.pause().then((_) {
            if (!mounted) return;
            if (stopToken != _segmentStopToken) return;
            _player.seek(Duration(milliseconds: (stopAt * 1000).round()));
            if (!mounted) return;
            if (stopToken != _segmentStopToken) return;
            _clearSegmentStopState();
          });
        }
      }
    });
    _player.durationStream.listen((duration) {
      if (!mounted || duration == null) return;
      setState(() => _duration = duration);
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final completed = state.processingState == ProcessingState.completed;
      setState(() {
        _isPlaying = state.playing;

        // Auto-complete or manual pause/stop should clear stale segment
        // stop markers so the next play press is not instantly paused.
        if (completed || !state.playing) {
          _clearSegmentStopState();
        }
      });
    });
  }

  void _clearSegmentStopState() {
    _segmentStopToken++;
    _segmentStopping = false;
    _playbackStopAtSeconds = null;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSongs() async {
    final stored = await SongStorage.loadAll();
    final entries = <_SongEntry>[];
    for (final s in stored) {
      final timestampIds =
          s.timestamps.map((timestamp) => timestamp.id).toSet();
      final shuffleTimestampIds =
          s.randomTimestampIds.intersection(timestampIds);
      final playedShuffleTimestampIds =
          s.playedRandomTimestampIds.intersection(shuffleTimestampIds);
      _shuffleTimestampIdsBySong[s.id] = shuffleTimestampIds;
      _playedShuffleTimestampIdsBySong[s.id] = playedShuffleTimestampIds;

      entries.add(_SongEntry(
        id: s.id,
        name: s.name,
        bytes: s.audioBytes,
        audioFileName: s.audioFileName,
        timestamps: s.timestamps,
      ));
    }
    if (mounted && entries.isNotEmpty) {
      setState(() {
        _songs.addAll(entries);
      });
    }
  }

  Future<void> _persistShuffleStateForSong(String songId) async {
    await SongStorage.updateRandomPlaybackState(
      songId,
      randomTimestampIds: Set<String>.from(_shuffleIdsForSong(songId)),
      playedRandomTimestampIds:
          Set<String>.from(_playedShuffleIdsForSong(songId)),
    );
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result;

    try {
      result = await FilePicker.platform
          .pickFiles(
            type: FileType.any,
            withData: true,
            withReadStream: true,
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

    if (result == null || result.files.isEmpty) {
      return;
    }

    var showingUploadLoader = false;
    try {
      final file = result.files.first;
      if (!_isSupportedAudioFile(file)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select an audio file (${_iosAudioExtensions.join(', ')}).',
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _isPreparingUpload = true);
      }
      showingUploadLoader = true;

      Uint8List? bytes = file.bytes;
      if (bytes == null && file.readStream != null) {
        bytes = await _readBytesFromStream(file.readStream!);
      }
      if (bytes == null) {
        if (mounted) {
          setState(() => _isPreparingUpload = false);
        }
        showingUploadLoader = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not read the selected audio file.')),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _isPreparingUpload = false);
      }
      showingUploadLoader = false;

      // Ask user for a display name
      final displayName = await _askForDisplayName(file.name);
      if (displayName == null) return; // user cancelled

      final songId = DateTime.now().microsecondsSinceEpoch.toString();
      final audioFileName =
          await SongStorage.saveAudioFile(songId, file.name, bytes);

      final song = _SongEntry(
        id: songId,
        name: displayName,
        bytes: bytes,
        audioFileName: audioFileName,
      );

      setState(() {
        _songs.add(song);
        _activeSongId = song.id;
        _activeTab = _HomeTab.player;
      });

      await SongStorage.addSong(StoredSong(
        id: song.id,
        name: song.name,
        audioFileName: audioFileName,
        audioBytes: bytes,
        timestamps: song.timestamps,
      ));

      await _loadSong(song);
    } catch (_) {
      if (showingUploadLoader && mounted) {
        setState(() => _isPreparingUpload = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process the selected file.')),
        );
      }
    }
  }

  bool _isSupportedAudioFile(PlatformFile file) {
    final extension =
        (file.extension ?? _extensionFromName(file.name))?.trim().toLowerCase();
    return extension != null && _supportedAudioExtensions.contains(extension);
  }

  String? _extensionFromName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return null;
    }
    return fileName.substring(dotIndex + 1);
  }

  Future<String?> _askForDisplayName(String originalFileName) async {
    // Strip extension for the default display name
    final dotIndex = originalFileName.lastIndexOf('.');
    final defaultName = dotIndex > 0
        ? originalFileName.substring(0, dotIndex)
        : originalFileName;
    final controller = TextEditingController(text: defaultName);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Name this song'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                originalFileName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Display name'),
                onSubmitted: (value) {
                  final name = value.trim();
                  Navigator.of(context).pop(name.isEmpty ? defaultName : name);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                Navigator.of(context).pop(name.isEmpty ? defaultName : name);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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

  Future<void> _loadSong(_SongEntry song) async {
    setState(() {
      _loadError = null;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;
      _segmentStopping = false;
      _playbackStopAtSeconds = null;
      _segmentTimestampIds.clear();
    });

    try {
      await _player.stop();

      if (song.bytes != null) {
        final source = AudioSource.uri(
          Uri.dataFromBytes(
            song.bytes!,
            mimeType: _mimeTypeFromFileName(song.audioFileName ?? song.name),
          ),
        );
        await _player.setAudioSource(source);
      } else {
        throw StateError('No path or bytes for selected audio file.');
      }
    } catch (_) {
      setState(() {
        _loadError = 'Could not load "${song.name}".';
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
      _clearSegmentStopState();
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  Future<void> _onSeek(Duration target) async {
    _clearSegmentStopState();
    await _player.seek(target);
  }

  void _onPlaybackSpeedChanged(double speed) {
    if (speed <= 0) return;
    setState(() => _selectedPlaybackSpeed = speed);
    unawaited(_player.setSpeed(speed));
  }

  double _speedToSliderValue(double speed) {
    final minLog = math.log(_minPlaybackSpeed);
    final maxLog = math.log(_maxPlaybackSpeed);
    final speedLog =
        math.log(speed.clamp(_minPlaybackSpeed, _maxPlaybackSpeed));
    return ((speedLog - minLog) / (maxLog - minLog)).clamp(0.0, 1.0);
  }

  double _sliderValueToSpeed(double value) {
    final minLog = math.log(_minPlaybackSpeed);
    final maxLog = math.log(_maxPlaybackSpeed);
    final mapped =
        math.exp(minLog + (value.clamp(0.0, 1.0) * (maxLog - minLog)));
    return double.parse(mapped.toStringAsFixed(3));
  }

  String _formatSpeed(double speed) {
    return '${speed.toStringAsFixed(2)}x';
  }

  double _snapSpeed(double speed) {
    var closest = speed;
    var bestDistance = double.infinity;
    for (final snapPoint in _speedSnapPoints) {
      final distance = (speed - snapPoint).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        closest = snapPoint;
      }
    }
    if (bestDistance <= _speedSnapThreshold) {
      return closest;
    }
    return speed;
  }

  double? _parseSpeedInput(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll('x', '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Future<void> _addTimestampAtCurrentTime() async {
    final song = _activeSong;
    if (song == null) return;

    final labelController = TextEditingController();
    final timeController = TextEditingController(
      text: _formatTimestampInputTime(_position.inMilliseconds / 1000),
    );

    final result = await showDialog<_TimestampDialogResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Name This Timestamp'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Timestamp name',
                  hintText: 'e.g. Chorus start',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Time',
                  hintText: 'e.g. 1:23 or 83.5',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsedSeconds =
                    _parseTimestampInputTime(timeController.text.trim());
                if (parsedSeconds == null || parsedSeconds < 0) {
                  Navigator.of(context).pop(
                    _TimestampDialogResult(
                      label: '__INVALID_TIME__',
                      seconds: -1,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop(
                  _TimestampDialogResult(
                    label: labelController.text.trim(),
                    seconds: parsedSeconds,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    if (result.label == '__INVALID_TIME__') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Invalid time. Use mm:ss or seconds, e.g. 1:23 or 83.5.'),
          ),
        );
      }
      return;
    }

    final timestamp = Timestamp(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      seconds: result.seconds,
      label: result.label,
    );

    setState(() {
      song.timestamps.add(timestamp);
      song.timestamps.sort((a, b) => a.seconds.compareTo(b.seconds));
    });
    await SongStorage.updateTimestamps(song.id, song.timestamps);
  }

  Future<void> _playFromTimestamp(Timestamp timestamp,
      {int leadInSeconds = 0}) async {
    setState(() {
      _clearSegmentStopState();
      _segmentTimestampIds.clear();
    });
    final startSeconds =
        math.max(0.0, timestamp.seconds - leadInSeconds.toDouble());
    await _player.seek(Duration(milliseconds: (startSeconds * 1000).round()));
    await _player.play();
  }

  _SegmentRange? _computeSegmentRange() {
    final song = _activeSong;
    if (song == null || _segmentTimestampIds.isEmpty) return null;

    final sorted = List<Timestamp>.from(song.timestamps)
      ..sort((a, b) => a.seconds.compareTo(b.seconds));
    final selectedSorted =
        sorted.where((m) => _segmentTimestampIds.contains(m.id)).toList();
    if (selectedSorted.isEmpty) return null;

    final firstSelected = selectedSorted.first;
    final lastSelected = selectedSorted.last;
    final lastIndex = sorted.indexWhere((m) => m.id == lastSelected.id);
    final end = lastIndex < sorted.length - 1
        ? sorted[lastIndex + 1].seconds
        : _duration.inMilliseconds / 1000;

    return _SegmentRange(firstSelected.seconds, end);
  }

  void _toggleSegmentMode(Timestamp timestamp) {
    setState(() {
      if (_segmentTimestampIds.contains(timestamp.id)) {
        _segmentTimestampIds.clear();
      } else {
        _segmentTimestampIds.add(timestamp.id);
      }
      _segmentStopping = false;
    });
  }

  Future<void> _playSegmentFromTimestamp() async {
    final range = _computeSegmentRange();
    if (range == null) return;
    final startSeconds =
        math.max(0.0, range.start - _selectedLeadInSeconds.toDouble());
    final stopSeconds = _applyLeadOut(range.end);
    setState(() {
      _segmentStopToken++;
      _segmentStopping = false;
      _playbackStopAtSeconds = stopSeconds;
    });
    await _player.seek(Duration(milliseconds: (startSeconds * 1000).round()));
    await _player.play();
  }

  double _applyLeadOut(double segmentEndSeconds) {
    final extendedEnd = segmentEndSeconds + _selectedLeadOutSeconds.toDouble();
    final maxDurationSeconds = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds / 1000.0
        : double.infinity;
    return math.min(extendedEnd, maxDurationSeconds);
  }

  Future<void> _toggleShuffleTimestamp(
      _SongEntry song, Timestamp timestamp) async {
    final shuffleIds = _shuffleIdsForSong(song.id);
    final playedShuffleIds = _playedShuffleIdsForSong(song.id);
    setState(() {
      if (shuffleIds.contains(timestamp.id)) {
        shuffleIds.remove(timestamp.id);
        playedShuffleIds.remove(timestamp.id);
      } else {
        shuffleIds.add(timestamp.id);
        playedShuffleIds.remove(timestamp.id);
      }
    });

    await _persistShuffleStateForSong(song.id);
  }

  Future<void> _resetShuffleSegments(_SongEntry song) async {
    setState(() {
      _playedShuffleIdsForSong(song.id).clear();
      _segmentTimestampIds.clear();
    });

    await _persistShuffleStateForSong(song.id);
  }

  int _shuffleSectionCount(_SongEntry song) {
    final ids = _shuffleIdsForSong(song.id);
    return song.timestamps
        .where((timestamp) => ids.contains(timestamp.id))
        .length;
  }

  int _remainingShuffleSectionCount(_SongEntry song) {
    final ids = _shuffleIdsForSong(song.id);
    final played = _playedShuffleIdsForSong(song.id);
    return song.timestamps
        .where((timestamp) =>
            ids.contains(timestamp.id) && !played.contains(timestamp.id))
        .length;
  }

  bool _hasShuffleEnabledTimestamps(_SongEntry song) {
    return _remainingShuffleSectionCount(song) > 0;
  }

  _ShuffleSegmentSelection? _selectShuffleSegment(_SongEntry song) {
    final shuffleIds = _shuffleIdsForSong(song.id);
    final playedShuffleIds = _playedShuffleIdsForSong(song.id);
    final sorted = List<Timestamp>.from(song.timestamps)
      ..sort((a, b) => a.seconds.compareTo(b.seconds));
    final selectableIndices = <int>[];
    final enabledIndices = <int>[];

    for (var index = 0; index < sorted.length; index++) {
      if (shuffleIds.contains(sorted[index].id)) {
        enabledIndices.add(index);
        if (!playedShuffleIds.contains(sorted[index].id)) {
          selectableIndices.add(index);
        }
      }
    }

    if (selectableIndices.isEmpty) return null;

    final startIndex =
        selectableIndices[math.Random().nextInt(selectableIndices.length)];
    final startEnabledIndex = enabledIndices.indexOf(startIndex);
    final nextEnabledIndex = (startEnabledIndex >= 0 &&
            startEnabledIndex < enabledIndices.length - 1)
        ? enabledIndices[startEnabledIndex + 1]
        : sorted.length;
    final stopAt = nextEnabledIndex < sorted.length
        ? sorted[nextEnabledIndex].seconds
        : (_duration.inMilliseconds / 1000.0);
    final timestampIds = sorted
        .sublist(startIndex, nextEnabledIndex)
        .map((timestamp) => timestamp.id)
        .toSet();

    return _ShuffleSegmentSelection(
      startTimestamp: sorted[startIndex],
      stopAt: stopAt,
      timestampIds: timestampIds,
    );
  }

  Future<void> _showShuffleMessage(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Shuffle'),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(message)),
              const SizedBox(width: 10),
              Icon(Icons.shuffle, color: colorScheme.primary),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSpeedDialog() async {
    var dialogSpeed = _selectedPlaybackSpeed;
    var isEditingSpeed = false;
    final speedController = TextEditingController(
      text: dialogSpeed.toStringAsFixed(2),
    );
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void applySpeed(
              double speed, {
              bool updateEditorText = true,
              bool clampToSliderRange = false,
            }) {
              if (speed <= 0) return;

              final nextSpeed = clampToSliderRange
                  ? _snapSpeed(
                      speed
                          .clamp(_minPlaybackSpeed, _maxPlaybackSpeed)
                          .toDouble(),
                    )
                  : ((speed >= _minPlaybackSpeed && speed <= _maxPlaybackSpeed)
                      ? _snapSpeed(speed)
                      : speed);

              setDialogState(() {
                dialogSpeed = nextSpeed;
                if (updateEditorText) {
                  speedController.text = nextSpeed.toStringAsFixed(2);
                  speedController.selection = TextSelection.fromPosition(
                    TextPosition(offset: speedController.text.length),
                  );
                }
              });
              _onPlaybackSpeedChanged(nextSpeed);
            }

            return AlertDialog(
              title: const Text('Playback Speed'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 64,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const sliderHorizontalInset = 24.0;
                          final usableWidth = constraints.maxWidth -
                              (sliderHorizontalInset * 2);
                          double tickLeftFor(double point) {
                            return sliderHorizontalInset +
                                (_speedToSliderValue(point) * usableWidth);
                          }

                          final slowTickLeft =
                              tickLeftFor(_speedSnapPoints.first);
                          final fastTickLeft =
                              tickLeftFor(_speedSnapPoints.last);
                          return Stack(
                            children: [
                              Positioned(
                                top: 0,
                                left: slowTickLeft - 8,
                                child: const Text(
                                  '🐢',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: fastTickLeft - 8,
                                child: const Text(
                                  '🐇',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              Positioned(
                                top: 20,
                                left: sliderHorizontalInset,
                                right: sliderHorizontalInset,
                                child: SizedBox(
                                  height: 12,
                                  child: Stack(
                                    children: _speedSnapPoints.map((point) {
                                      final left = _speedToSliderValue(point) *
                                          usableWidth;
                                      return Positioned(
                                        left: left - 1.5,
                                        child: Container(
                                          width: 3,
                                          height: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 16,
                                child: Slider(
                                  value: _speedToSliderValue(dialogSpeed),
                                  onChanged: (value) {
                                    final speed = _sliderValueToSpeed(value);
                                    applySpeed(
                                      speed,
                                      clampToSliderRange: true,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isEditingSpeed)
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            isEditingSpeed = true;
                            speedController.text =
                                dialogSpeed.toStringAsFixed(2);
                            speedController.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: speedController.text.length),
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Text(
                            _formatSpeed(dialogSpeed),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: speedController,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Speed',
                          ),
                          onChanged: (value) {
                            final parsed = _parseSpeedInput(value);
                            if (parsed != null) {
                              applySpeed(parsed, updateEditorText: false);
                            }
                          },
                          onSubmitted: (value) {
                            final parsed = _parseSpeedInput(value);
                            if (parsed != null) {
                              applySpeed(parsed);
                            }
                            setDialogState(() => isEditingSpeed = false);
                          },
                          onTapOutside: (_) {
                            final parsed =
                                _parseSpeedInput(speedController.text);
                            if (parsed != null) {
                              applySpeed(parsed);
                            }
                            setDialogState(() => isEditingSpeed = false);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
    speedController.dispose();
  }

  Future<void> _playShuffleSegment() async {
    final song = _activeSong;
    if (song == null) return;

    if (_shuffleSectionCount(song) == 0) {
      await _showShuffleMessage(
        'Please select segments for shuffling first.',
      );
      return;
    }

    if (_remainingShuffleSectionCount(song) == 0) {
      await _showShuffleMessage(
        'All selected shuffle segments were already played. Long-press shuffle to reset.',
      );
      return;
    }

    final selection = _selectShuffleSegment(song);
    if (selection == null) return;

    final startSeconds = math.max(0.0,
        selection.startTimestamp.seconds - _selectedLeadInSeconds.toDouble());

    setState(() {
      _playedShuffleIdsForSong(song.id).add(selection.startTimestamp.id);
      _segmentStopToken++;
      _segmentStopping = false;
      _playbackStopAtSeconds = _applyLeadOut(selection.stopAt);
      _segmentTimestampIds
        ..clear()
        ..addAll(selection.timestampIds);
    });

    await _persistShuffleStateForSong(song.id);

    await _player.seek(Duration(milliseconds: (startSeconds * 1000).round()));
    await _player.play();
  }

  Future<void> _deleteTimestamp(_SongEntry song, Timestamp timestamp) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete timestamp?'),
          content: Text(
            timestamp.label.isEmpty
                ? 'This timestamp will be removed permanently.'
                : '"${timestamp.label}" will be removed permanently.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      song.timestamps.removeWhere((m) => m.id == timestamp.id);
    });
    _shuffleIdsForSong(song.id).remove(timestamp.id);
    _playedShuffleIdsForSong(song.id).remove(timestamp.id);
    await SongStorage.updateTimestamps(song.id, song.timestamps);
  }

  Future<void> _renameSong(_SongEntry song) async {
    final controller = TextEditingController(text: song.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename song'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Song name'),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty || newName == song.name) return;

    final idx = _songs.indexWhere((s) => s.id == song.id);
    if (idx == -1) return;

    setState(() {
      _songs[idx] = _SongEntry(
        id: song.id,
        name: newName,
        bytes: song.bytes,
        audioFileName: song.audioFileName,
        timestamps: song.timestamps,
      );
    });

    await SongStorage.renameSong(song.id, newName);
  }

  Future<void> _deleteSongFromLibrary(_SongEntry song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete song?'),
          content: Text(
            'Do you really want to delete "${song.name}" with '
            '${song.timestamps.length} timestamp(s)? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (_activeSongId == song.id) {
      await _player.stop();
      setState(() {
        _activeSongId = null;
        _activeTab = _HomeTab.library;
      });
    }

    setState(() {
      _songs.removeWhere((s) => s.id == song.id);
    });

    _shuffleTimestampIdsBySong.remove(song.id);
    _playedShuffleTimestampIdsBySong.remove(song.id);

    await SongStorage.deleteSong(song.id);
  }

  String _formatSeconds(double s) {
    final total = s.round();
    final m = total ~/ 60;
    final sec = total % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String _formatTimestampInputTime(double seconds) {
    final total = seconds.round();
    final m = total ~/ 60;
    final sec = total % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  double? _parseTimestampInputTime(String raw) {
    if (raw.isEmpty) return null;

    if (raw.contains(':')) {
      final parts = raw.split(':');
      if (parts.length != 2) return null;
      final minutes = int.tryParse(parts[0].trim());
      final seconds = double.tryParse(parts[1].trim());
      if (minutes == null || seconds == null) return null;
      return (minutes * 60) + seconds;
    }

    return double.tryParse(raw);
  }

  Future<void> _openSongFromLibrary(_SongEntry song) async {
    setState(() {
      _activeSongId = song.id;
      _activeTab = _HomeTab.player;
    });
    await _loadSong(song);
  }

  Widget _buildLibraryView() {
    return Column(
      children: [
        Expanded(
          child: _songs.isEmpty
              ? const Center(
                  child: Text('No songs yet. Upload your first song below.'),
                )
              : ListView.separated(
                  itemCount: _songs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return ListTile(
                      title: Text(song.name),
                      subtitle: Text(
                        '${song.timestamps.length} timestamp(s)',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _renameSong(song),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteSongFromLibrary(song),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _openSongFromLibrary(song),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isPreparingUpload ? null : _pickAudio,
              icon: _isPreparingUpload
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                    _isPreparingUpload ? 'Preparing Upload...' : 'Upload Song'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerView() {
    final song = _activeSong;
    final hasAudio = song != null && _loadError == null;
    final hasShuffleEnabled =
        song != null && _hasShuffleEnabledTimestamps(song);
    final shuffleSectionsTotal = song != null ? _shuffleSectionCount(song) : 0;
    final shuffleSectionsRemaining =
        song != null ? _remainingShuffleSectionCount(song) : 0;
    final leadInValue = _leadInSecondOptions.contains(_selectedLeadInSeconds)
        ? _selectedLeadInSeconds
        : _leadInSecondOptions.first;
    final leadOutValue = _leadOutSecondOptions.contains(_selectedLeadOutSeconds)
        ? _selectedLeadOutSeconds
        : 3;
    if (song == null) {
      return const Center(
        child: Text('No song selected. Open Library and choose a song.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (song.audioFileName != null)
                Text(
                  song.audioFileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
            ],
          ),
        ),
        if (hasAudio)
          WaveformPlayer(
            position: _position,
            duration: _duration,
            isPlaying: _isPlaying,
            enabled: true,
            waveformSeed: song.name,
            onPlayPause: _onPlayPause,
            onSaveTimestamp: _addTimestampAtCurrentTime,
            onShufflePlay: _playShuffleSegment,
            onShuffleReset: () async => _resetShuffleSegments(song),
            onToggleSpeed: () => unawaited(_showSpeedDialog()),
            speedLabel: _formatSpeed(_selectedPlaybackSpeed),
            shufflePlayEnabled: hasShuffleEnabled,
            shuffleSectionsTotal: shuffleSectionsTotal,
            shuffleSectionsRemaining: shuffleSectionsRemaining,
            onSeek: _onSeek,
          )
        else
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _loadError ?? 'Song selected, but audio is not loaded yet.',
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Wrap(
            spacing: 16,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lead-in'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: leadInValue,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedLeadInSeconds = value);
                    },
                    items: _leadInSecondOptions
                        .map(
                          (s) => DropdownMenuItem<int>(
                            value: s,
                            child: Text('$s s'),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lead-out'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: leadOutValue,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedLeadOutSeconds = value);
                    },
                    items: _leadOutSecondOptions
                        .map(
                          (s) => DropdownMenuItem<int>(
                            value: s,
                            child: Text('$s s'),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: song.timestamps.isEmpty
                ? const Center(child: Text('No timestamps yet.'))
                : ListView.separated(
                    itemCount: song.timestamps.length,
                    separatorBuilder: (_, i) {
                      if (i < song.timestamps.length - 1 &&
                          _segmentTimestampIds
                              .contains(song.timestamps[i].id) &&
                          _segmentTimestampIds
                              .contains(song.timestamps[i + 1].id)) {
                        return const SizedBox.shrink();
                      }
                      return const Divider(height: 1);
                    },
                    itemBuilder: (context, i) {
                      final timestamp = song.timestamps[i];
                      final isShuffleEnabled =
                          _shuffleIdsForSong(song.id).contains(timestamp.id);
                      final title = timestamp.label.isEmpty
                          ? 'Timestamp ${i + 1}'
                          : timestamp.label;
                      final isSegment =
                          _segmentTimestampIds.contains(timestamp.id);
                      final prevSelected = i > 0 &&
                          _segmentTimestampIds
                              .contains(song.timestamps[i - 1].id);
                      final nextSelected = i < song.timestamps.length - 1 &&
                          _segmentTimestampIds
                              .contains(song.timestamps[i + 1].id);

                      final range = _computeSegmentRange();

                      BorderRadius tileBorder = BorderRadius.zero;
                      if (isSegment) {
                        final top = prevSelected
                            ? Radius.zero
                            : const Radius.circular(8);
                        final bottom = nextSelected
                            ? Radius.zero
                            : const Radius.circular(8);
                        tileBorder = BorderRadius.only(
                          topLeft: top,
                          topRight: top,
                          bottomLeft: bottom,
                          bottomRight: bottom,
                        );
                      }

                      final isFirstInSegment = isSegment && !prevSelected;
                      const timestampLeadingWidth = 40.0;
                      final segmentRangeLabel = (isFirstInSegment &&
                              range != null)
                          ? '${_formatSeconds(range.start)} → ${_formatSeconds(range.end)}'
                          : null;

                      final tile = ListTile(
                        dense: true,
                        minLeadingWidth: timestampLeadingWidth,
                        horizontalTitleGap: 8,
                        onLongPress: hasAudio
                            ? () => _toggleSegmentMode(timestamp)
                            : null,
                        leading: isSegment && !isFirstInSegment
                            ? const SizedBox(width: timestampLeadingWidth)
                            : SizedBox(
                                width: timestampLeadingWidth,
                                height: timestampLeadingWidth,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: timestampLeadingWidth,
                                    height: timestampLeadingWidth,
                                  ),
                                  icon: Icon(
                                    isFirstInSegment
                                        ? Icons.skip_next
                                        : Icons.play_arrow,
                                  ),
                                  onPressed: hasAudio
                                      ? () {
                                          if (isFirstInSegment) {
                                            _playSegmentFromTimestamp();
                                          } else {
                                            _playFromTimestamp(
                                              timestamp,
                                              leadInSeconds:
                                                  _selectedLeadInSeconds,
                                            );
                                          }
                                        }
                                      : null,
                                ),
                              ),
                        title: isFirstInSegment && segmentRangeLabel != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    segmentRangeLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                  ),
                                  Text(title),
                                ],
                              )
                            : Text(title),
                        subtitle: Text(_formatSeconds(timestamp.seconds)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shuffle),
                              color: isShuffleEnabled
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              onPressed: () async =>
                                  _toggleShuffleTimestamp(song, timestamp),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _deleteTimestamp(song, timestamp),
                            ),
                          ],
                        ),
                      );

                      if (!isSegment) return tile;

                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: tileBorder,
                        ),
                        child: tile,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Expanded(
              child: Text(
                '5-6-7-8 Beta',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            SegmentedButton<_HomeTab>(
              segments: const [
                ButtonSegment<_HomeTab>(
                  value: _HomeTab.library,
                  label: Text('Library'),
                  icon: Icon(Icons.library_music),
                ),
                ButtonSegment<_HomeTab>(
                  value: _HomeTab.player,
                  label: Text('Player'),
                  icon: Icon(Icons.graphic_eq),
                ),
              ],
              selected: <_HomeTab>{_activeTab},
              onSelectionChanged: (selection) {
                setState(() {
                  _activeTab = selection.first;
                });
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                minimumSize: WidgetStateProperty.all(
                  const Size(0, 36),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
      body: _activeTab == _HomeTab.library
          ? _buildLibraryView()
          : _buildPlayerView(),
    );
  }
}
