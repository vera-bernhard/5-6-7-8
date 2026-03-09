class Marker {
  final String id;
  final double seconds;
  final String label;

  Marker({required this.id, required this.seconds, this.label = ''});

  Marker copyWith({String? id, double? seconds, String? label}) => Marker(
      id: id ?? this.id,
      seconds: seconds ?? this.seconds,
      label: label ?? this.label);

  Map<String, dynamic> toJson() => {
        'id': id,
        'seconds': seconds,
        'label': label,
      };

  factory Marker.fromJson(Map<String, dynamic> json) => Marker(
        id: json['id'] as String,
        seconds: (json['seconds'] as num).toDouble(),
        label: json['label'] as String? ?? '',
      );
}
