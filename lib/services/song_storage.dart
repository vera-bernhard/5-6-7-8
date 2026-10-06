import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song_analysis.dart';
import '../models/timestamp.dart';

Map<String, dynamic> _asStringKeyedMap(dynamic raw) {
  if (raw is Map) {
    return raw.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  throw const FormatException('Expected map value.');
}

class StoredSong {
  final String id;
  final String name;
  final String audioFileName;
  final Uint8List audioBytes;
  final List<Timestamp> timestamps;
  final Set<String> randomTimestampIds;
  final Set<String> playedRandomTimestampIds;
  final SongAnalysis? analysis;

  StoredSong({
    required this.id,
    required this.name,
    required this.audioFileName,
    required this.audioBytes,
    required this.timestamps,
    Set<String>? randomTimestampIds,
    Set<String>? playedRandomTimestampIds,
    this.analysis,
  })  : randomTimestampIds = randomTimestampIds ?? <String>{},
        playedRandomTimestampIds = playedRandomTimestampIds ?? <String>{};

  static Set<String> _parseStringSet(dynamic raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).toSet();
    }
    return <String>{};
  }

  StoredSong copyWith({
    String? name,
    List<Timestamp>? timestamps,
    Set<String>? randomTimestampIds,
    Set<String>? playedRandomTimestampIds,
    SongAnalysis? analysis,
  }) =>
      StoredSong(
        id: id,
        name: name ?? this.name,
        audioFileName: audioFileName,
        audioBytes: audioBytes,
        timestamps: timestamps ?? this.timestamps,
        randomTimestampIds: randomTimestampIds ?? this.randomTimestampIds,
        playedRandomTimestampIds:
            playedRandomTimestampIds ?? this.playedRandomTimestampIds,
        analysis: analysis ?? this.analysis,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'audioFileName': audioFileName,
        'audioBytes': audioBytes,
        'timestamps':
            timestamps.map((timestamp) => timestamp.toJson()).toList(),
        'randomTimestampIds': randomTimestampIds.toList(),
        'playedRandomTimestampIds': playedRandomTimestampIds.toList(),
        if (analysis != null) 'analysis': analysis!.toJson(),
      };

  factory StoredSong.fromJson(Map<String, dynamic> json) {
    final rawTimestamps =
        json['timestamps'] ?? json['markers'] ?? const <dynamic>[];
    final timestamps = rawTimestamps is List
        ? rawTimestamps
            .map(
                (timestamp) => Timestamp.fromJson(_asStringKeyedMap(timestamp)))
            .toList()
        : <Timestamp>[];
    final randomTimestampIds = _parseStringSet(
      json['randomTimestampIds'] ?? json['shuffleTimestampIds'],
    );
    final playedRandomTimestampIds =
        _parseStringSet(json['playedRandomTimestampIds']);

    SongAnalysis? analysis;
    final rawAnalysis = json['analysis'];
    if (rawAnalysis != null) {
      try {
        analysis = SongAnalysis.fromJson(_asStringKeyedMap(rawAnalysis));
      } catch (error) {
        debugPrint('Ignoring unreadable song analysis: $error');
      }
    }

    return StoredSong(
      id: json['id'] as String,
      name: json['name'] as String,
      audioFileName: json['audioFileName'] as String,
      audioBytes: _parseAudioBytes(json['audioBytes']),
      timestamps: timestamps,
      randomTimestampIds: randomTimestampIds,
      playedRandomTimestampIds:
          playedRandomTimestampIds.intersection(randomTimestampIds),
      analysis: analysis,
    );
  }

  static Uint8List _parseAudioBytes(dynamic raw) {
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    if (raw is List<dynamic>) {
      return Uint8List.fromList(raw.map((e) => e as int).toList());
    }
    return Uint8List(0);
  }
}

class SongStorage {
  static const String _boxName = 'songs_storage';
  static const String _songsKey = 'songs';
  static Box<dynamic>? _box;

  // All writes load the whole index and save it again, so they run one after
  // another. Otherwise a background analysis save could overwrite a
  // timestamp that was added at the same time.
  static Future<void> _writeQueue = Future<void>.value();

  static Future<void> _serialized(Future<void> Function() write) {
    final result = _writeQueue.then((_) => write());
    _writeQueue = result.catchError((Object _) {});
    return result;
  }

  static Future<void> _updateSong(
      String songId, StoredSong Function(StoredSong song) update) {
    return _serialized(() async {
      final songs = await loadAll();
      final idx = songs.indexWhere((s) => s.id == songId);
      if (idx == -1) return;
      songs[idx] = update(songs[idx]);
      await _saveIndex(songs);
    });
  }

  static Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  static Future<Box<dynamic>> _getBox() async {
    await init();
    return _box!;
  }

  static Future<List<StoredSong>> loadAll() async {
    final box = await _getBox();
    final raw = box.get(_songsKey, defaultValue: <dynamic>[]);
    if (raw is! List) return <StoredSong>[];

    final songs = <StoredSong>[];
    for (final entry in raw) {
      try {
        songs.add(StoredSong.fromJson(_asStringKeyedMap(entry)));
      } catch (error, stackTrace) {
        debugPrint('Skipping unreadable stored song: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return songs;
  }

  static Future<void> _saveIndex(List<StoredSong> songs) async {
    final box = await _getBox();
    await box.put(_songsKey, songs.map((s) => s.toJson()).toList());
  }

  static Future<String> saveAudioFile(
      String songId, String originalName, Uint8List bytes) async {
    final ext = originalName.contains('.')
        ? originalName.substring(originalName.lastIndexOf('.'))
        : '';
    return '$songId$ext';
  }

  static Future<String?> getAudioFilePath(String audioFileName) async {
    return null;
  }

  static Future<void> addSong(StoredSong song) {
    return _serialized(() async {
      final songs = await loadAll();
      songs.removeWhere((s) => s.id == song.id);
      songs.add(song);
      await _saveIndex(songs);
    });
  }

  static Future<void> updateTimestamps(
      String songId, List<Timestamp> timestamps) {
    // Copy, so later in-memory edits don't change what is being saved.
    final copy = List<Timestamp>.from(timestamps);
    return _updateSong(songId, (song) {
      final timestampIds = copy.map((timestamp) => timestamp.id).toSet();
      final randomTimestampIds =
          song.randomTimestampIds.intersection(timestampIds);
      return song.copyWith(
        timestamps: copy,
        randomTimestampIds: randomTimestampIds,
        playedRandomTimestampIds:
            song.playedRandomTimestampIds.intersection(randomTimestampIds),
      );
    });
  }

  static Future<void> updateRandomPlaybackState(
    String songId, {
    required Set<String> randomTimestampIds,
    required Set<String> playedRandomTimestampIds,
  }) {
    final randomCopy = Set<String>.from(randomTimestampIds);
    final playedCopy = Set<String>.from(playedRandomTimestampIds);
    return _updateSong(songId, (song) {
      final timestampIds =
          song.timestamps.map((timestamp) => timestamp.id).toSet();
      final filteredRandomIds = randomCopy.intersection(timestampIds);
      return song.copyWith(
        randomTimestampIds: filteredRandomIds,
        playedRandomTimestampIds: playedCopy.intersection(filteredRandomIds),
      );
    });
  }

  static Future<void> renameSong(String songId, String newName) {
    return _updateSong(songId, (song) => song.copyWith(name: newName));
  }

  static Future<void> updateAnalysis(String songId, SongAnalysis analysis) {
    return _updateSong(songId, (song) => song.copyWith(analysis: analysis));
  }

  static Future<void> deleteSong(String songId) {
    return _serialized(() async {
      final songs = await loadAll();
      songs.removeWhere((s) => s.id == songId);
      await _saveIndex(songs);
    });
  }
}
