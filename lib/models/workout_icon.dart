import 'package:flutter/material.dart';

/// 운동 아이콘 한 개를 나타내는 모델.
/// `imageBase64`(사용자가 갤러리에서 추가한 이미지) 또는
/// `iconCodePoint`+`iconFontFamily`(내장 벡터 아이콘) 중 하나로 시각적으로
/// 표현하고, `type`으로 Type1/Type2 탭을 구분한다.
///
/// 이모지 대신 Flutter 내장 아이콘 폰트를 쓰는 이유: 일부 플랫폼/렌더러
/// 조합(Skia·Impeller)에서 컬러 이모지 글리프가 깨진 사각형(tofu)으로
/// 표시되는 문제가 있어, 항상 동일하게 그려지는 벡터 아이콘을 사용한다.
class WorkoutIcon {
  static int _counter = 0;

  /// 위젯 key 용도로만 쓰이는 세션 내 고유 id (직렬화하지 않음).
  final int id;

  int? iconCodePoint;
  String? iconFontFamily;
  String? iconFontPackage;
  String? imageBase64;
  String name;
  String type; // 'type1' or 'type2'

  WorkoutIcon({
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    this.imageBase64,
    required this.name,
    required this.type,
  }) : id = _counter++;

  WorkoutIcon.fromIconData(
    IconData icon, {
    this.imageBase64,
    required this.name,
    required this.type,
  })  : iconCodePoint = icon.codePoint,
        iconFontFamily = icon.fontFamily,
        iconFontPackage = icon.fontPackage,
        id = _counter++;

  bool get isImage => imageBase64 != null && imageBase64!.isNotEmpty;

  IconData? get iconData => iconCodePoint == null
      ? null
      : IconData(
          iconCodePoint!,
          fontFamily: iconFontFamily,
          fontPackage: iconFontPackage,
        );

  factory WorkoutIcon.fromJson(Map<String, dynamic> json) {
    return WorkoutIcon(
      iconCodePoint: json['iconCodePoint'] as int?,
      iconFontFamily: json['iconFontFamily'] as String?,
      iconFontPackage: json['iconFontPackage'] as String?,
      imageBase64: json['imageBase64'] as String?,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'type1',
    );
  }

  Map<String, dynamic> toJson() => {
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'iconFontPackage': iconFontPackage,
        'imageBase64': imageBase64,
        'name': name,
        'type': type,
      };
}

List<WorkoutIcon> defaultWorkoutIcons() => [
      WorkoutIcon.fromIconData(Icons.fitness_center, name: '근력', type: 'type1'),
      WorkoutIcon.fromIconData(Icons.sports_gymnastics, name: '역도', type: 'type1'),
      WorkoutIcon.fromIconData(Icons.sports_mma, name: '복싱', type: 'type1'),
      WorkoutIcon.fromIconData(Icons.terrain, name: '클라이밍', type: 'type1'),
      WorkoutIcon.fromIconData(Icons.directions_run, name: '유산소', type: 'type2'),
      WorkoutIcon.fromIconData(Icons.directions_bike, name: '사이클', type: 'type2'),
      WorkoutIcon.fromIconData(Icons.pool, name: '수영', type: 'type2'),
      WorkoutIcon.fromIconData(Icons.self_improvement, name: '요가', type: 'type2'),
      WorkoutIcon.fromIconData(Icons.sports_tennis, name: '테니스', type: 'type2'),
      WorkoutIcon.fromIconData(Icons.sports_soccer, name: '축구', type: 'type2'),
    ];
