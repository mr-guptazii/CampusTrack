/// Subject model. Stored in Firestore at subjects/{uid}/items/{id} and
/// cached locally in a Hive box as a plain Map (no code-generated adapter
/// required — keeps the project buildable without build_runner).
class Subject {
  final String id;
  final String name;
  final String code;
  final String faculty;
  final int attended;
  final int total;
  final double targetPercentage;
  final int colorValue;
  final String icon;
  final DateTime updatedAt;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.faculty,
    required this.attended,
    required this.total,
    required this.targetPercentage,
    required this.colorValue,
    required this.icon,
    required this.updatedAt,
  });

  double get percentage => total == 0 ? 0 : (attended / total) * 100;

  bool get isBelowTarget => percentage < targetPercentage;

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    String? faculty,
    int? attended,
    int? total,
    double? targetPercentage,
    int? colorValue,
    String? icon,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      faculty: faculty ?? this.faculty,
      attended: attended ?? this.attended,
      total: total ?? this.total,
      targetPercentage: targetPercentage ?? this.targetPercentage,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'faculty': faculty,
        'attended': attended,
        'total': total,
        'targetPercentage': targetPercentage,
        'colorValue': colorValue,
        'icon': icon,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Subject.fromJson(Map<dynamic, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String? ?? '',
        faculty: json['faculty'] as String? ?? '',
        attended: (json['attended'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        targetPercentage: (json['targetPercentage'] as num?)?.toDouble() ?? 75.0,
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF2563EB,
        icon: json['icon'] as String? ?? 'book',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  factory Subject.empty(String id) => Subject(
        id: id,
        name: '',
        code: '',
        faculty: '',
        attended: 0,
        total: 0,
        targetPercentage: 75.0,
        colorValue: 0xFF2563EB,
        icon: 'book',
        updatedAt: DateTime.now(),
      );
}
