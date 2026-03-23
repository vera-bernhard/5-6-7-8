import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  StoredSong({
    required this.id,
    required this.name,
    required this.audioFileName,
    required this.audioBytes,
    required this.timestamps,
    Set<String>? randomTimestampIds,
    Set<String>? playedRandomTimestampIds,
  })  : randomTimestampIds = randomTimestampIds ?? <String>{},
        playedRandomTimestampIds = playedRandomTimestampIds ?? <String>{};

  static Set<String> _parseStringSet(dynamic raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).toSet();
    }
    return <String>{};
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'audioFileName': audioFileName,
        'audioBytes': audioBytes,
        'timestamps':
            timestamps.map((timestamp) => timestamp.toJson()).toList(),
        'randomTimestampIds': randomTimestampIds.toList(),
        'playedRandomTimestampIds': playedRandomTimestampIds.toList(),
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

    return StoredSong(
      id: json['id'] as String,
      name: json['name'] as String,
      audioFileName: json['audioFileName'] as String,
      audioBytes: _parseAudioBytes(json['audioBytes']),
      timestamps: timestamps,
      randomTimestampIds: randomTimestampIds,
      playedRandomTimestampIds:
          playedRandomTimestampIds.intersection(randomTimestampIds),
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

  static Future<void> addSong(StoredSong song) async {
    final songs = await loadAll();
    songs.removeWhere((s) => s.id == song.id);
    songs.add(song);
    await _saveIndex(songs);
  }

  static Future<void> updateTimestamps(
      String songId, List<Timestamp> timestamps) async {
    final songs = await loadAll();
    final idx = songs.indexWhere((s) => s.id == songId);
    if (idx == -1) return;
    final timestampIds = timestamps.map((timestamp) => timestamp.id).toSet();
    final randomTimestampIds =
        songs[idx].randomTimestampIds.intersection(timestampIds);
    final playedRandomTimestampIds =
        songs[idx].playedRandomTimestampIds.intersection(randomTimestampIds);
    songs[idx] = StoredSong(
      id: songs[idx].id,
      name: songs[idx].name,
      audioFileName: songs[idx].audioFileName,
      audioBytes: songs[idx].audioBytes,
      timestamps: timestamps,
      randomTimestampIds: randomTimestampIds,
      playedRandomTimestampIds: playedRandomTimestampIds,
    );
    await _saveIndex(songs);
  }

  static Future<void> updateRandomPlaybackState(
    String songId, {
    required Set<String> randomTimestampIds,
    required Set<String> playedRandomTimestampIds,
  }) async {
    final songs = await loadAll();
    final idx = songs.indexWhere((s) => s.id == songId);
    if (idx == -1) return;
    final timestampIds =
        songs[idx].timestamps.map((timestamp) => timestamp.id).toSet();
    final filteredRandomIds = randomTimestampIds.intersection(timestampIds);
    final filteredPlayedIds =
        playedRandomTimestampIds.intersection(filteredRandomIds);

    songs[idx] = StoredSong(
      id: songs[idx].id,
      name: songs[idx].name,
      audioFileName: songs[idx].audioFileName,
      audioBytes: songs[idx].audioBytes,
      timestamps: songs[idx].timestamps,
      randomTimestampIds: filteredRandomIds,
      playedRandomTimestampIds: filteredPlayedIds,
    );
    await _saveIndex(songs);
  }

  static Future<void> renameSong(String songId, String newName) async {
    final songs = await loadAll();
    final idx = songs.indexWhere((s) => s.id == songId);
    if (idx == -1) return;
    songs[idx] = StoredSong(
      id: songs[idx].id,
      name: newName,
      audioFileName: songs[idx].audioFileName,
      audioBytes: songs[idx].audioBytes,
      timestamps: songs[idx].timestamps,
      randomTimestampIds: songs[idx].randomTimestampIds,
      playedRandomTimestampIds: songs[idx].playedRandomTimestampIds,
    );
    await _saveIndex(songs);
  }

  static Future<void> deleteSong(String songId) async {
    final songs = await loadAll();
    songs.removeWhere((s) => s.id == songId);
    await _saveIndex(songs);
  }
}
