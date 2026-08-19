/// 저장된 운동 기록 한 건.
class WorkoutRecord {
  int? iconCodePoint;
  String? iconFontFamily;
  String? iconFontPackage;
  String? iconImagePath;

  /// 구버전 호환용(과거엔 이미지를 base64로 직접 저장했다). 새 기록은
  /// [iconImagePath]만 채워진다.
  String? iconImageBase64;
  String iconName;
  String name;
  String date; // yyyy-MM-dd
  String weight;
  String reps;

  WorkoutRecord({
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    this.iconImagePath,
    this.iconImageBase64,
    required this.iconName,
    required this.name,
    required this.date,
    required this.weight,
    required this.reps,
  });

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
        iconCodePoint: json['iconCodePoint'] as int?,
        iconFontFamily: json['iconFontFamily'] as String?,
        iconFontPackage: json['iconFontPackage'] as String?,
        iconImagePath: json['iconImagePath'] as String?,
        iconImageBase64: json['iconImageBase64'] as String?,
        iconName: json['iconName'] as String? ?? '',
        name: json['name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        weight: json['weight'] as String? ?? '',
        reps: json['reps'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'iconFontPackage': iconFontPackage,
        'iconImagePath': iconImagePath,
        'iconImageBase64': iconImageBase64,
        'iconName': iconName,
        'name': name,
        'date': date,
        'weight': weight,
        'reps': reps,
      };
}
