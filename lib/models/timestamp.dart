class Timestamp {
  final String id;
  final double seconds;
  final String label;

  Timestamp({required this.id, required this.seconds, this.label = ''});

  Timestamp copyWith({String? id, double? seconds, String? label}) => Timestamp(
        id: id ?? this.id,
        seconds: seconds ?? this.seconds,
        label: label ?? this.label,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'seconds': seconds,
        'label': label,
      };

  factory Timestamp.fromJson(Map<String, dynamic> json) => Timestamp(
        id: json['id'] as String,
        seconds: (json['seconds'] as num).toDouble(),
        label: json['label'] as String? ?? '',
      );
}
