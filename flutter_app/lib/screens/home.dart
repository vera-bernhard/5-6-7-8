import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/waveform_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/marker_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _audioPath;

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _audioPath = result.files.first.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = ref.watch(markerListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Timestamp Trainer')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _audioPath == null
                  ? const Text('No audio selected')
                  : WaveformPlayer(audioPath: _audioPath!),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: markers.length,
              itemBuilder: (context, i) {
                final m = markers[i];
                return ListTile(
                  title: Text(m.label.isEmpty ? 'Marker ${i + 1}' : m.label),
                  subtitle: Text('${m.seconds.toStringAsFixed(2)} s'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => ref.read(markerListProvider.notifier).removeMarker(m.id),
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
            onPressed: () {
              // add a sample marker at 0s for demo
              ref.read(markerListProvider.notifier).addMarker(0.0, label: 'New marker');
            },
            child: const Icon(Icons.add_location),
          ),
        ],
      ),
    );
  }
}
