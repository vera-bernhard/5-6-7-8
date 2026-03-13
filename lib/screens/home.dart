import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import '../widgets/waveform_player.dart';
import '../models/marker.dart';
import '../services/song_storage.dart';

enum _HomeTab { library, player }

class _SegmentRange {
  final double start;
  final double end;
  _SegmentRange(this.start, this.end);
}

class _SongEntry {
  final String id;
  final String name;
  final Uint8List? bytes;
  final String? audioFileName;
  final List<Marker> markers;

  _SongEntry({
    required this.id,
    required this.name,
    this.bytes,
    this.audioFileName,
    List<Marker>? markers,
  }) : markers = markers ?? <Marker>[];
}

class _MarkerDialogResult {
  final String label;
  final double seconds;

  _MarkerDialogResult({required this.label, required this.seconds});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AudioPlayer _player;
  static const List<int> _leadInSecondOptions = <int>[0, 1, 3, 5];

  final List<_SongEntry> _songs = <_SongEntry>[];
  String? _activeSongId;
  _HomeTab _activeTab = _HomeTab.library;

  String? _loadError;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  int _selectedLeadInSeconds = 0;

  bool _segmentStopping = false;

  final Set<String> _segmentMarkerIds = {};

  _SongEntry? get _activeSong {
    if (_activeSongId == null) return null;
    for (final s in _songs) {
      if (s.id == _activeSongId) return s;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadSavedSongs();
    _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
      final range = _computeSegmentRange();
      if (range != null && _isPlaying && !_segmentStopping) {
        final currentSec = position.inMilliseconds / 1000.0;
        if (currentSec >= range.end) {
          _segmentStopping = true;
          _player.pause().then((_) {
            if (!mounted) return;
            _player.seek(Duration(milliseconds: (range.end * 1000).round()));
            setState(() {
              _segmentStopping = false;
            });
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
      setState(() => _isPlaying = state.playing);
    });
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
      entries.add(_SongEntry(
        id: s.id,
        name: s.name,
        bytes: s.audioBytes,
        audioFileName: s.audioFileName,
        markers: s.markers,
      ));
    }
    if (mounted && entries.isNotEmpty) {
      setState(() {
        _songs.addAll(entries);
      });
    }
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform
          .pickFiles(
            type: FileType.audio,
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

    try {
      final file = result.files.first;
      Uint8List? bytes = file.bytes;

      if (bytes == null && file.readStream != null) {
        bytes = await _readBytesFromStream(file.readStream!);
      }

      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not read the selected audio file.')),
          );
        }
        return;
      }

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
        markers: song.markers,
      ));

      await _loadSong(song);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process the selected file.')),
        );
      }
    }
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
      _segmentMarkerIds.clear();
    });

    try {
      await _player.stop();

      if (kIsWeb) {
        if (song.bytes != null) {
          final source = AudioSource.uri(
            Uri.dataFromBytes(
              song.bytes!,
              mimeType: _mimeTypeFromFileName(song.audioFileName ?? song.name),
            ),
          );
          await _player.setAudioSource(source);
        } else {
          throw StateError('No browser-loadable bytes were provided.');
        }
      } else if (song.bytes != null) {
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
      await _player.play();
    }
  }

  Future<void> _onSeek(Duration target) async {
    await _player.seek(target);
  }

  Future<void> _addMarkerAtCurrentTime() async {
    final song = _activeSong;
    if (song == null) return;

    final labelController = TextEditingController();
    final timeController = TextEditingController(
      text: _formatMarkerInputTime(_position.inMilliseconds / 1000),
    );

    final result = await showDialog<_MarkerDialogResult>(
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
                  labelText: 'Marker name',
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
                    _parseMarkerInputTime(timeController.text.trim());
                if (parsedSeconds == null || parsedSeconds < 0) {
                  Navigator.of(context).pop(
                    _MarkerDialogResult(
                      label: '__INVALID_TIME__',
                      seconds: -1,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop(
                  _MarkerDialogResult(
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

    final marker = Marker(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      seconds: result.seconds,
      label: result.label,
    );

    setState(() {
      song.markers.add(marker);
      song.markers.sort((a, b) => a.seconds.compareTo(b.seconds));
    });
    SongStorage.updateMarkers(song.id, song.markers);
  }

  Future<void> _playFromMarker(Marker marker, {int leadInSeconds = 0}) async {
    setState(() {
      _segmentStopping = false;
      _segmentMarkerIds.clear();
    });
    final startSeconds =
        math.max(0.0, marker.seconds - leadInSeconds.toDouble());
    await _player.seek(Duration(milliseconds: (startSeconds * 1000).round()));
    await _player.play();
  }

  _SegmentRange? _computeSegmentRange() {
    final song = _activeSong;
    if (song == null || _segmentMarkerIds.isEmpty) return null;

    final sorted = List<Marker>.from(song.markers)
      ..sort((a, b) => a.seconds.compareTo(b.seconds));
    final selectedSorted =
        sorted.where((m) => _segmentMarkerIds.contains(m.id)).toList();
    if (selectedSorted.isEmpty) return null;

    final firstSelected = selectedSorted.first;
    final lastSelected = selectedSorted.last;
    final lastIndex = sorted.indexWhere((m) => m.id == lastSelected.id);
    final end = lastIndex < sorted.length - 1
        ? sorted[lastIndex + 1].seconds
        : _duration.inMilliseconds / 1000;

    return _SegmentRange(firstSelected.seconds, end);
  }

  void _toggleSegmentMode(Marker marker) {
    setState(() {
      if (_segmentMarkerIds.contains(marker.id)) {
        _segmentMarkerIds.remove(marker.id);
      } else {
        _segmentMarkerIds.add(marker.id);
      }
      _segmentStopping = false;
    });
  }

  Future<void> _playSegmentFromMarker() async {
    final range = _computeSegmentRange();
    if (range == null) return;
    final startSeconds =
        math.max(0.0, range.start - _selectedLeadInSeconds.toDouble());
    setState(() => _segmentStopping = false);
    await _player.seek(Duration(milliseconds: (startSeconds * 1000).round()));
    await _player.play();
  }

  Future<void> _deleteMarker(_SongEntry song, Marker marker) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete marker?'),
          content: Text(
            marker.label.isEmpty
                ? 'This marker will be removed permanently.'
                : '"${marker.label}" will be removed permanently.',
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
      song.markers.removeWhere((m) => m.id == marker.id);
    });
    SongStorage.updateMarkers(song.id, song.markers);
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
        markers: song.markers,
      );
    });

    SongStorage.renameSong(song.id, newName);
  }

  Future<void> _deleteSongFromLibrary(_SongEntry song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete song?'),
          content: Text(
            'Do you really want to delete "${song.name}" with '
            '${song.markers.length} marker(s)? This cannot be undone.',
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

    SongStorage.deleteSong(song.id);
  }

  String _formatSeconds(double s) {
    final total = s.round();
    final m = total ~/ 60;
    final sec = total % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String _formatMarkerInputTime(double seconds) {
    final total = seconds.round();
    final m = total ~/ 60;
    final sec = total % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  double? _parseMarkerInputTime(String raw) {
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
                        '${song.markers.length} marker(s)',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Rename',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _renameSong(song),
                          ),
                          IconButton(
                            tooltip: 'Delete',
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
              onPressed: _pickAudio,
              icon: const Icon(Icons.upload_file),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Upload Song'),
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

    if (song == null) {
      return const Center(
        child: Text('No song selected. Open Library and choose a song.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasAudio ? _addMarkerAtCurrentTime : null,
              icon: const Icon(Icons.bookmark_add),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Save Marker'),
              ),
            ),
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
          child: Row(
            children: [
              const Text('Lead-in'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _selectedLeadInSeconds,
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
            child: song.markers.isEmpty
                ? const Center(child: Text('No markers yet.'))
                : ListView.separated(
                    itemCount: song.markers.length,
                    separatorBuilder: (_, i) {
                      if (i < song.markers.length - 1 &&
                          _segmentMarkerIds.contains(song.markers[i].id) &&
                          _segmentMarkerIds.contains(song.markers[i + 1].id)) {
                        return const SizedBox.shrink();
                      }
                      return const Divider(height: 1);
                    },
                    itemBuilder: (context, i) {
                      final marker = song.markers[i];
                      final title = marker.label.isEmpty
                          ? 'Marker ${i + 1}'
                          : marker.label;
                      final isSegment = _segmentMarkerIds.contains(marker.id);
                      final prevSelected = i > 0 &&
                          _segmentMarkerIds.contains(song.markers[i - 1].id);
                      final nextSelected = i < song.markers.length - 1 &&
                          _segmentMarkerIds.contains(song.markers[i + 1].id);

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

                      final tile = ListTile(
                        dense: true,
                        leading: GestureDetector(
                          onLongPress: hasAudio
                              ? () => _toggleSegmentMode(marker)
                              : null,
                          child: isSegment && !isFirstInSegment
                              ? const SizedBox(width: 48)
                              : IconButton(
                                  icon: Icon(
                                    isFirstInSegment
                                        ? Icons.skip_next
                                        : Icons.play_arrow,
                                  ),
                                  onPressed: hasAudio
                                      ? () {
                                          if (isFirstInSegment) {
                                            _playSegmentFromMarker();
                                          } else {
                                            _playFromMarker(
                                              marker,
                                              leadInSeconds:
                                                  _selectedLeadInSeconds,
                                            );
                                          }
                                        }
                                      : null,
                                ),
                        ),
                        title: Text(title),
                        subtitle: Text(
                          isFirstInSegment && range != null
                              ? '${_formatSeconds(range.start)} → ${_formatSeconds(range.end)}'
                              : _formatSeconds(marker.seconds),
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete marker',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteMarker(song, marker),
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
        title: const Text('5-6-7-8'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: SegmentedButton<_HomeTab>(
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
                minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
              ),
            ),
          ),
          Expanded(
            child: _activeTab == _HomeTab.library
                ? _buildLibraryView()
                : _buildPlayerView(),
          ),
        ],
      ),
    );
  }
}
