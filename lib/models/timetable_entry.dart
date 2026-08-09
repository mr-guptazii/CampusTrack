import '../core/utils/date_utils.dart';

/// A single weekly recurring class slot.
class TimetableEntry {
  final String id;
  final Weekday day;
  final String subjectId;
  final String startTime; // "HH:mm" 24h
  final String endTime; // "HH:mm" 24h
  final String room;

  const TimetableEntry({
    required this.id,
    required this.day,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  int get startMinutes => AppDateUtils.minutesSinceMidnight(startTime);
  int get endMinutes => AppDateUtils.minutesSinceMidnight(endTime);

  bool isOngoingAt(DateTime now) {
    if (WeekdayX.fromDateTime(now) != day) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  bool isUpcomingToday(DateTime now) {
    if (WeekdayX.fromDateTime(now) != day) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes < startMinutes;
  }

  TimetableEntry copyWith({
    String? id,
    Weekday? day,
    String? subjectId,
    String? startTime,
    String? endTime,
    String? room,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      day: day ?? this.day,
      subjectId: subjectId ?? this.subjectId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day.index,
        'subjectId': subjectId,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
      };

  factory TimetableEntry.fromJson(Map<dynamic, dynamic> json) => TimetableEntry(
        id: json['id'] as String,
        day: WeekdayX.fromIndex((json['day'] as num?)?.toInt() ?? 0),
        subjectId: json['subjectId'] as String,
        startTime: json['startTime'] as String? ?? '09:00',
        endTime: json['endTime'] as String? ?? '10:00',
        room: json['room'] as String? ?? '',
      );
}
