// 코드포인트가 저장된 값에서 런타임에 조립되므로 const로 만들 수 없다.
// 여기서 쓰이는 코드포인트는 모두 defaultWorkoutIcons()의 const Icons.*
// 참조를 통해 폰트 트리쉐이킹 대상에 이미 포함되므로 release 빌드에서도
// 아이콘이 누락되지 않는다.
// ignore_for_file: non_const_argument_for_const_parameter

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// 운동 아이콘 한 개를 나타내는 모델.
/// `imagePath`(사용자가 갤러리에서 추가해 앱 저장소에 복사해둔 이미지 파일 경로,
/// 과거 데이터 호환용으로 `imageBase64`도 읽을 수 있다) 또는
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
  String? imagePath;

  /// 구버전 호환용: 예전엔 이미지를 base64로 SharedPreferences에 직접
  /// 저장했다. 새 이미지는 항상 파일로 저장되고 [imagePath]를 쓰지만,
  /// 기존에 저장돼 있던 값을 읽을 수 있도록 필드는 유지한다.
  String? imageBase64;
  String name;
  String type; // 'type1' or 'type2'

  /// 내장 기본 아이콘(근력/역도/... 10개)인 경우에만 채워지는 식별자.
  /// null이면 사용자가 갤러리에서 추가한 커스텀 아이콘이다.
  final String? defaultKey;

  /// 사용자가 [name]을 직접 수정한 적이 있으면 true. false인 동안은
  /// [displayName]이 [defaultKey]를 기준으로 현재 로케일 이름을 매번
  /// 새로 계산해 보여주고, 한 번 수정되면 그때부터는 저장된 [name]을
  /// 그대로 보여준다(기기 언어를 바꿔도 사용자가 지은 이름은 유지).
  bool nameCustomized;

  WorkoutIcon({
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    this.imagePath,
    this.imageBase64,
    required this.name,
    required this.type,
    this.defaultKey,
    this.nameCustomized = false,
  }) : id = _counter++;

  WorkoutIcon.fromIconData(
    IconData icon, {
    this.imagePath,
    this.imageBase64,
    required this.name,
    required this.type,
    this.defaultKey,
    this.nameCustomized = false,
  })  : iconCodePoint = icon.codePoint,
        iconFontFamily = icon.fontFamily,
        iconFontPackage = icon.fontPackage,
        id = _counter++;

  bool get isImage =>
      (imagePath != null && imagePath!.isNotEmpty) ||
      (imageBase64 != null && imageBase64!.isNotEmpty);

  IconData? get iconData => iconCodePoint == null
      ? null
      : IconData(
          iconCodePoint!,
          fontFamily: iconFontFamily,
          fontPackage: iconFontPackage,
        );

  /// 실제로 화면에 표시할 이름. 기본 아이콘이면서 아직 사용자가 이름을
  /// 고치지 않았다면 [loc]의 현재 로케일로 번역된 이름을 매번 새로
  /// 계산해서 보여주고, 그 외(커스텀 아이콘이거나 이름을 수정한 경우)는
  /// 저장된 [name]을 그대로 보여준다.
  String displayName(AppLocalizations loc) {
    if (!nameCustomized) {
      final localized = _localizedDefaultName(loc);
      if (localized != null) return localized;
    }
    return name;
  }

  String? _localizedDefaultName(AppLocalizations loc) {
    switch (defaultKey) {
      case 'strength':
        return loc.iconNameStrength;
      case 'weightlifting':
        return loc.iconNameWeightlifting;
      case 'boxing':
        return loc.iconNameBoxing;
      case 'climbing':
        return loc.iconNameClimbing;
      case 'cardio':
        return loc.iconNameCardio;
      case 'cycling':
        return loc.iconNameCycling;
      case 'swimming':
        return loc.iconNameSwimming;
      case 'yoga':
        return loc.iconNameYoga;
      case 'tennis':
        return loc.iconNameTennis;
      case 'soccer':
        return loc.iconNameSoccer;
      default:
        return null;
    }
  }

  factory WorkoutIcon.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return WorkoutIcon(
      iconCodePoint: json['iconCodePoint'] as int?,
      iconFontFamily: json['iconFontFamily'] as String?,
      iconFontPackage: json['iconFontPackage'] as String?,
      imagePath: json['imagePath'] as String?,
      imageBase64: json['imageBase64'] as String?,
      name: name,
      type: json['type'] as String? ?? 'type1',
      // defaultKey가 없는 예전 데이터는, 이 기능이 생기기 전엔 기본
      // 아이콘 이름이 항상 한국어로 저장됐다는 점을 이용해 이름으로
      // 역추정한다. 사용자가 직접 같은 이름으로 바꾼 커스텀 아이콘이
      // 우연히 겹칠 수는 있지만 드문 경우라 감수한다.
      defaultKey: json['defaultKey'] as String? ?? _legacyDefaultKeyFor(name),
      nameCustomized: json['nameCustomized'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'iconFontPackage': iconFontPackage,
        'imagePath': imagePath,
        'imageBase64': imageBase64,
        'name': name,
        'type': type,
        'defaultKey': defaultKey,
        'nameCustomized': nameCustomized,
      };

  static const Map<String, String> _legacyKoreanDefaultNames = {
    '근력': 'strength',
    '역도': 'weightlifting',
    '복싱': 'boxing',
    '클라이밍': 'climbing',
    '유산소': 'cardio',
    '사이클': 'cycling',
    '수영': 'swimming',
    '요가': 'yoga',
    '테니스': 'tennis',
    '축구': 'soccer',
  };

  static String? _legacyDefaultKeyFor(String name) => _legacyKoreanDefaultNames[name];
}

/// 최초 실행(저장된 아이콘이 없을 때) 기본으로 제공하는 아이콘 목록.
/// [name]은 저장용 초기값일 뿐이고, 실제 화면 표시는 [WorkoutIcon.displayName]이
/// `defaultKey`를 기준으로 매번 현재 로케일에 맞게 다시 계산한다 — 즉 기기
/// 언어를 바꾸면 이름도 그에 맞춰 바뀐다. 사용자가 이름을 직접 고치면
/// `nameCustomized`가 true가 되어 그 순간부터는 언어를 바꿔도 유지된다.
List<WorkoutIcon> defaultWorkoutIcons(AppLocalizations loc) => [
      WorkoutIcon.fromIconData(Icons.fitness_center, name: loc.iconNameStrength, type: 'type1', defaultKey: 'strength'),
      WorkoutIcon.fromIconData(Icons.sports_gymnastics, name: loc.iconNameWeightlifting, type: 'type1', defaultKey: 'weightlifting'),
      WorkoutIcon.fromIconData(Icons.sports_mma, name: loc.iconNameBoxing, type: 'type1', defaultKey: 'boxing'),
      WorkoutIcon.fromIconData(Icons.terrain, name: loc.iconNameClimbing, type: 'type1', defaultKey: 'climbing'),
      WorkoutIcon.fromIconData(Icons.directions_run, name: loc.iconNameCardio, type: 'type2', defaultKey: 'cardio'),
      WorkoutIcon.fromIconData(Icons.directions_bike, name: loc.iconNameCycling, type: 'type2', defaultKey: 'cycling'),
      WorkoutIcon.fromIconData(Icons.pool, name: loc.iconNameSwimming, type: 'type2', defaultKey: 'swimming'),
      WorkoutIcon.fromIconData(Icons.self_improvement, name: loc.iconNameYoga, type: 'type2', defaultKey: 'yoga'),
      WorkoutIcon.fromIconData(Icons.sports_tennis, name: loc.iconNameTennis, type: 'type2', defaultKey: 'tennis'),
      WorkoutIcon.fromIconData(Icons.sports_soccer, name: loc.iconNameSoccer, type: 'type2', defaultKey: 'soccer'),
    ];
