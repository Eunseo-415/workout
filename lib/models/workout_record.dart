/// 저장된 운동 기록 한 건.
class WorkoutRecord {
  final String id;
  String exerciseKey;
  String name;
  String date; // yyyy-MM-dd
  int durationMinutes;

  WorkoutRecord({
    required this.id,
    required this.exerciseKey,
    required this.name,
    required this.date,
    required this.durationMinutes,
  });

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
        id: json['id'] as String? ??
            'w${DateTime.now().microsecondsSinceEpoch}',
        exerciseKey: json['exerciseKey'] as String? ?? 'strength',
        name: json['name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        // 구버전(weight/reps 기반) 데이터에는 이 필드가 없으므로 0으로 대체된다.
        durationMinutes: json['durationMinutes'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseKey': exerciseKey,
        'name': name,
        'date': date,
        'durationMinutes': durationMinutes,
      };
}
