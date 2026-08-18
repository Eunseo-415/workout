/// 운동 아이콘 한 개를 나타내는 모델.
/// `emoji`(이모지) 또는 `imageBase64`(사용자가 갤러리에서 추가한 이미지) 중
/// 하나를 사용해 시각적으로 표현하고, `type`으로 Type1/Type2 탭을 구분한다.
class WorkoutIcon {
  static int _counter = 0;

  /// 위젯 key 용도로만 쓰이는 세션 내 고유 id (직렬화하지 않음).
  final int id;

  String? emoji;
  String? imageBase64;
  String name;
  String type; // 'type1' or 'type2'

  WorkoutIcon({
    this.emoji,
    this.imageBase64,
    required this.name,
    required this.type,
  }) : id = _counter++;

  bool get isImage => imageBase64 != null && imageBase64!.isNotEmpty;

  factory WorkoutIcon.fromJson(Map<String, dynamic> json) {
    return WorkoutIcon(
      emoji: json['emoji'] as String?,
      imageBase64: json['imageBase64'] as String?,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'type1',
    );
  }

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'imageBase64': imageBase64,
        'name': name,
        'type': type,
      };
}

List<WorkoutIcon> defaultWorkoutIcons() => [
      WorkoutIcon(emoji: '💪', name: '근력', type: 'type1'),
      WorkoutIcon(emoji: '🏋️', name: '역도', type: 'type1'),
      WorkoutIcon(emoji: '🥊', name: '복싱', type: 'type1'),
      WorkoutIcon(emoji: '🧗', name: '클라이밍', type: 'type1'),
      WorkoutIcon(emoji: '🏃', name: '유산소', type: 'type2'),
      WorkoutIcon(emoji: '🚴', name: '사이클', type: 'type2'),
      WorkoutIcon(emoji: '🏊', name: '수영', type: 'type2'),
      WorkoutIcon(emoji: '🧘', name: '요가', type: 'type2'),
      WorkoutIcon(emoji: '🎾', name: '테니스', type: 'type2'),
      WorkoutIcon(emoji: '⚽', name: '축구', type: 'type2'),
    ];
