import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/marker.dart';

class StoredSong {
  final String id;
  final String name;
  final String audioFileName;
  final List<Marker> markers;

  StoredSong({
    required this.id,
    required this.name,
    required this.audioFileName,
    required this.markers,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'audioFileName': audioFileName,
        'markers': markers.map((m) => m.toJson()).toList(),
      };

  factory StoredSong.fromJson(Map<String, dynamic> json) => StoredSong(
        id: json['id'] as String,
        name: json['name'] as String,
        audioFileName: json['audioFileName'] as String,
        markers: (json['markers'] as List<dynamic>)
            .map((m) => Marker.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class SongStorage {
  static const _indexFile = 'songs_index.json';

  static Future<Directory> _songsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/songs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<List<StoredSong>> loadAll() async {
    if (kIsWeb) return [];
    final dir = await _songsDir();
    final indexFile = File('${dir.path}/$_indexFile');
    if (!await indexFile.exists()) return [];

    try {
      final content = await indexFile.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list
          .map((e) => StoredSong.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveIndex(List<StoredSong> songs) async {
    final dir = await _songsDir();
    final indexFile = File('${dir.path}/$_indexFile');
    final json = jsonEncode(songs.map((s) => s.toJson()).toList());
    await indexFile.writeAsString(json);
  }

  static Future<String> saveAudioFile(
      String songId, String originalName, Uint8List bytes) async {
    final dir = await _songsDir();
    final ext = originalName.contains('.')
        ? originalName.substring(originalName.lastIndexOf('.'))
        : '';
    final audioFileName = '$songId$ext';
    final file = File('${dir.path}/$audioFileName');
    await file.writeAsBytes(bytes);
    return audioFileName;
  }

  static Future<String?> getAudioFilePath(String audioFileName) async {
    final dir = await _songsDir();
    final file = File('${dir.path}/$audioFileName');
    if (await file.exists()) return file.path;
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
      markers: songs[idx].markers,
    );
    await _saveIndex(songs);
  }

  static Future<void> deleteSong(String songId) async {
    final songs = await loadAll();
    final matches = songs.where((s) => s.id == songId);
    final song = matches.isEmpty ? null : matches.first;
    if (song != null) {
      final dir = await _songsDir();
      final audioFile = File('${dir.path}/${song.audioFileName}');
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    }
    songs.removeWhere((s) => s.id == songId);
    await _saveIndex(songs);
  }
}
