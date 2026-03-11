import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marker.dart';
import 'package:uuid/uuid.dart';

class MarkerListNotifier extends StateNotifier<List<Marker>> {
  MarkerListNotifier() : super([]);
  final _uuid = const Uuid();

  void addMarker(double seconds, {String label = ''}) {
    final m = Marker(id: _uuid.v4(), seconds: seconds, label: label);
    state = [...state, m];
  }

  void removeMarker(String id) => state = state.where((m) => m.id != id).toList();

  void updateMarker(String id, double seconds, {String? label}) {
    state = state
        .map((m) => m.id == id ? m.copyWith(seconds: seconds, label: label ?? m.label) : m)
        .toList();
  }
}

final markerListProvider = StateNotifierProvider<MarkerListNotifier, List<Marker>>((ref) => MarkerListNotifier());
