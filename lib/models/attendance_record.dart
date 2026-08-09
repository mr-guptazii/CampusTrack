enum AttendanceStatus { present, absent, cancelled, extra }

extension AttendanceStatusX on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.cancelled:
        return 'Cancelled';
      case AttendanceStatus.extra:
        return 'Extra Class';
    }
  }

  /// Whether this status counts towards the "total classes held" figure
  /// used in percentage calculations. Cancelled classes don't count.
  bool get countsTowardsTotal =>
      this == AttendanceStatus.present ||
      this == AttendanceStatus.absent ||
      this == AttendanceStatus.extra;

  bool get countsAsAttended =>
      this == AttendanceStatus.present || this == AttendanceStatus.extra;

  static AttendanceStatus fromName(String name) => AttendanceStatus.values
      .firstWhere((e) => e.name == name, orElse: () => AttendanceStatus.present);
}

/// A single attendance mark for one subject on one date.
class AttendanceRecord {
  final String id;
  final String subjectId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime timestamp;
  final String? note;
  final bool synced;

  const AttendanceRecord({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.status,
    required this.timestamp,
    this.note,
    this.synced = false,
  });

  AttendanceRecord copyWith({
    String? id,
    String? subjectId,
    DateTime? date,
    AttendanceStatus? status,
    DateTime? timestamp,
    String? note,
    bool? synced,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'date': date.toIso8601String(),
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
        'synced': synced,
      };

  factory AttendanceRecord.fromJson(Map<dynamic, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        date: DateTime.parse(json['date'] as String),
        status: AttendanceStatusX.fromName(json['status'] as String? ?? 'present'),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        note: json['note'] as String?,
        synced: json['synced'] as bool? ?? false,
      );
}
