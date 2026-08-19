import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_icon.dart';
import '../models/workout_record.dart';

/// HTML 버전의 localStorage 를 대체하는 영구 저장소.
class StorageService {
  static const _iconsKey = 'iconList';
  static const _workoutsKey = 'workouts';

  /// [defaultIcons]는 저장된 아이콘이 하나도 없을 때(최초 실행 등)만 쓰인다.
  /// 호출하는 쪽에서 현재 로케일로 번역된 기본 아이콘 목록을 넘겨준다.
  Future<List<WorkoutIcon>> loadIcons(List<WorkoutIcon> defaultIcons) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_iconsKey);
    if (raw == null || raw.isEmpty) return defaultIcons;
    try {
      final decoded = jsonDecode(raw) as List;
      final icons = decoded
          .map((e) => WorkoutIcon.fromJson(e as Map<String, dynamic>))
          .toList();
      return icons.isEmpty ? defaultIcons : icons;
    } catch (_) {
      return defaultIcons;
    }
  }

  Future<void> saveIcons(List<WorkoutIcon> icons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _iconsKey,
      jsonEncode(icons.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<WorkoutRecord>> loadWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_workoutsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => WorkoutRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWorkouts(List<WorkoutRecord> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _workoutsKey,
      jsonEncode(workouts.map((e) => e.toJson()).toList()),
    );
  }
}
