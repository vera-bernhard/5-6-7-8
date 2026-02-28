class Marker {
  final String id;
  final double seconds;
  final String label;

  Marker({required this.id, required this.seconds, this.label = ''});

  Marker copyWith({String? id, double? seconds, String? label}) =>
      Marker(id: id ?? this.id, seconds: seconds ?? this.seconds, label: label ?? this.label);
}
