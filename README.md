# workout

심플 운동 기록장 - Flutter 앱

원본 HTML 프로토타입을 Flutter로 이식한 운동 기록 앱입니다. Type1(근력/기본)·Type2(유산소/기타) 탭으로 운동 아이콘을 분류하고, 아이콘 이름/타입/순서 편집, 갤러리 이미지로 커스텀 아이콘 추가, 운동 기록(종목/날짜/중량/횟수) 추가 및 삭제 기능을 제공합니다. 데이터는 기기에 `shared_preferences`로 저장됩니다.

## 실행 방법

```bash
flutter pub get
flutter run
```

이 저장소에는 `lib/`와 `pubspec.yaml`만 포함되어 있습니다. 플랫폼별 실행 파일(android/ios/web/...)이 필요하면 프로젝트 루트에서 아래 명령으로 생성하세요.

```bash
flutter create .
```

## 프로젝트 구조

```
lib/
  main.dart                  # 앱 진입점, 테마 설정
  models/
    workout_icon.dart        # 아이콘 모델 (이모지/이미지, 타입)
    workout_record.dart      # 운동 기록 모델
  services/
    storage_service.dart     # shared_preferences 저장/불러오기
  widgets/
    icon_visual.dart         # 이모지/이미지 아이콘 렌더링 위젯
  screens/
    home_screen.dart         # 메인 화면 (아이콘 선택, 설정, 기록 입력/목록)
assets/
  app_icon/
    icon-1024.png            # App Store 제출용 마스터 아이콘 (1024x1024, 알파 없음)
    icon-source.svg          # 아이콘 벡터 원본 (수정 가능)
```

## 앱 아이콘 적용

`assets/app_icon/icon-1024.png` 하나로 iOS/Android 전체 사이즈 아이콘(iOS `AppIcon.appiconset` 포함)을 자동 생성하도록 `flutter_launcher_icons`가 설정되어 있습니다.

```bash
flutter create .              # android/ios 폴더가 없다면 먼저 생성
flutter pub get
dart run flutter_launcher_icons
```

실행하면 `ios/Runner/Assets.xcassets/AppIcon.appiconset`와 `android/app/src/main/res/mipmap-*` 아이콘이 모두 갱신됩니다. App Store Connect에는 `assets/app_icon/icon-1024.png`를 1024x1024 마케팅 아이콘으로 그대로 사용할 수 있습니다.
