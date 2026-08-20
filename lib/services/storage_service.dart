import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';
import '../models/workout_record.dart';

/// HTML 버전의 localStorage 를 대체하는 영구 저장소.
class StorageService {
  static const _customExercisesKey = 'customExercises';
  static const _workoutsKey = 'workouts';

  Future<List<CustomExercise>> loadCustomExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customExercisesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => CustomExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomExercises(List<CustomExercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customExercisesKey,
      jsonEncode(exercises.map((e) => e.toJson()).toList()),
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
