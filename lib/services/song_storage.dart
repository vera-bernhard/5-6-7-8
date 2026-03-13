import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/marker.dart';

class StoredSong {
  final String id;
  final String name;
  final String audioFileName;
  final Uint8List audioBytes;
  final List<Marker> markers;

  StoredSong({
    required this.id,
    required this.name,
    required this.audioFileName,
    required this.audioBytes,
    required this.markers,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'audioFileName': audioFileName,
        'audioBytes': audioBytes,
        'markers': markers.map((m) => m.toJson()).toList(),
      };

  factory StoredSong.fromJson(Map<String, dynamic> json) => StoredSong(
        id: json['id'] as String,
        name: json['name'] as String,
        audioFileName: json['audioFileName'] as String,
        audioBytes: _parseAudioBytes(json['audioBytes']),
        markers: (json['markers'] as List<dynamic>)
            .map((m) => Marker.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

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
    final raw = box.get(_songsKey, defaultValue: <dynamic>[]) as List<dynamic>;

    try {
      return raw
          .map((e) => StoredSong.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
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

  static Future<void> updateMarkers(String songId, List<Marker> markers) async {
    final songs = await loadAll();
    final idx = songs.indexWhere((s) => s.id == songId);
    if (idx == -1) return;
    songs[idx] = StoredSong(
      id: songs[idx].id,
      name: songs[idx].name,
      audioFileName: songs[idx].audioFileName,
      audioBytes: songs[idx].audioBytes,
      markers: markers,
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
      markers: songs[idx].markers,
    );
    await _saveIndex(songs);
  }

  static Future<void> deleteSong(String songId) async {
    final songs = await loadAll();
    songs.removeWhere((s) => s.id == songId);
    await _saveIndex(songs);
  }
}
