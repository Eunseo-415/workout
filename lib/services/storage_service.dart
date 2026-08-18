import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_icon.dart';
import '../models/workout_record.dart';

/// HTML 버전의 localStorage 를 대체하는 영구 저장소.
class StorageService {
  static const _iconsKey = 'iconList';
  static const _workoutsKey = 'workouts';

  Future<List<WorkoutIcon>> loadIcons() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_iconsKey);
    if (raw == null || raw.isEmpty) return defaultWorkoutIcons();
    try {
      final decoded = jsonDecode(raw) as List;
      final icons = decoded
          .map((e) => WorkoutIcon.fromJson(e as Map<String, dynamic>))
          .toList();
      return icons.isEmpty ? defaultWorkoutIcons() : icons;
    } catch (_) {
      return defaultWorkoutIcons();
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
