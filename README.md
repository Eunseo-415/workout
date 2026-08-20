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
    workout_icon.dart        # 아이콘 모델 (벡터 아이콘/이미지, 타입)
    workout_record.dart      # 운동 기록 모델
  services/
    storage_service.dart     # shared_preferences 저장/불러오기
  widgets/
    icon_visual.dart         # 벡터 아이콘/이미지 렌더링 위젯
  screens/
    home_screen.dart         # 메인 화면 (아이콘 선택, 설정, 기록 입력/목록)
assets/
  app_icon/
    icon-1024.png            # App Store 마케팅 아이콘 (1024x1024, 알파 없음)
    icon-source.svg          # 아이콘 벡터 원본 (수정 가능)
    AppIcon.appiconset/      # iOS용 전체 사이즈 아이콘 세트 (iPhone+iPad+마케팅, Contents.json 포함)
```

## 앱 아이콘 적용

### iOS

`assets/app_icon/AppIcon.appiconset/`에 iPhone·iPad·App Store 마케팅 아이콘까지 필요한 사이즈가 전부(iPad Pro 167x167, iPad 152x152 포함) 들어 있습니다. `ios/` 폴더가 있다면 이 폴더 내용을 그대로 복사해서 교체하세요.

```bash
cp -R assets/app_icon/AppIcon.appiconset/. ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

복사 후 Xcode에서 Product → Clean Build Folder 한 뒤 다시 Archive/업로드하면 "Missing required icon file" 검증 오류가 해결됩니다.

> `flutter_launcher_icons`(아래 참고)로 자동 생성한 아이콘은 iPad 전용 사이즈(152/167)가 빠지는 경우가 있어, iOS는 이 폴더를 직접 복사하는 방법을 권장합니다.

### Android (및 iOS 재생성)

`assets/app_icon/icon-1024.png` 하나로 Android 전체 사이즈 아이콘을 자동 생성하도록 `flutter_launcher_icons`가 설정되어 있습니다.

```bash
flutter create .              # android/ios 폴더가 없다면 먼저 생성
flutter pub get
dart run flutter_launcher_icons
```

iOS 아이콘까지 다시 생성했다면, 생성된 `AppIcon.appiconset`에 iPad 사이즈(152x152, 167x167)가 포함됐는지 `Contents.json`에서 꼭 확인하세요. 빠져 있다면 위의 `assets/app_icon/AppIcon.appiconset/`로 다시 덮어써야 합니다.

## 앱 이름 다국어 처리

앱과 관련된 "이름"은 두 곳에 따로 존재하고, 각각 다른 방법으로 언어별로 다르게 설정합니다.

### 1. App Store 검색/스토어 페이지 이름 (App Store 지역·언어 기준)

App Store Connect → 앱 정보 → 로케일 추가(예: 한국어, English (U.S.)) → 로케일마다 "이름"을 따로 입력. 코드 변경 없이 App Store Connect에서만 설정합니다.

### 2. 홈 화면 아이콘 아래 표시되는 이름 (기기 시스템 언어 기준)

`ios_localization/`에 언어별 `InfoPlist.strings`를 준비해뒀습니다.

```
ios_localization/
  ko.lproj/InfoPlist.strings   # CFBundleDisplayName = "심플한 캘린더 운동기록";
  en.lproj/InfoPlist.strings   # CFBundleDisplayName = "Simplest Workout Calendar";
```

적용 방법 (`ios/` 폴더가 있는 상태에서):

1. `ios/Runner.xcworkspace`를 Xcode로 엽니다.
2. 프로젝트 내비게이터에서 파란 프로젝트 아이콘(**Runner** 프로젝트, 타깃 아님) 선택 → **Info** 탭 → **Localizations** 섹션 → `+` 클릭 → **Korean (ko)** 추가 (English는 보통 기본으로 이미 있음).
3. `ios/Runner/`에 `InfoPlist.strings` 파일이 아직 없다면: File → New → File → **Strings File**로 `InfoPlist.strings` 생성 → File Inspector에서 **Localize...** 클릭 → English/Korean 체크.
4. 생성된 `ios/Runner/en.lproj/InfoPlist.strings`, `ios/Runner/ko.lproj/InfoPlist.strings`의 내용을 이 저장소의 `ios_localization/en.lproj/InfoPlist.strings`, `ios_localization/ko.lproj/InfoPlist.strings` 내용으로 각각 교체(또는 새로 복사)합니다.
5. Product → Clean Build Folder 후 다시 빌드/아카이브.

이렇게 하면 기기 언어를 한국어로 쓰는 사용자와 영어로 쓰는 사용자에게 홈 화면 아이콘 이름이 다르게 보입니다.
