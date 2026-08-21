import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/exercise.dart';
import '../models/workout_record.dart';
import '../theme/app_theme.dart';
import 'exercise_icon.dart';

class RecordTile extends StatelessWidget {
  final WorkoutRecord record;
  final AppLocalizations loc;
  final List<CustomExercise> customExercises;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecordTile({
    super.key,
    required this.record,
    required this.loc,
    required this.customExercises,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final h = record.durationMinutes ~/ 60;
    final m = record.durationMinutes % 60;
    final summary =
        h > 0 ? loc.durationHoursMinutes(h, m) : loc.durationMinutesOnly(m);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: ExerciseIcon(
              exerciseKey: record.exerciseKey,
              customExercises: customExercises,
              size: 16,
              color: AppColors.accent700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: DefaultTextStyle.of(context)
                        .style
                        .copyWith(fontSize: 14, color: AppColors.text),
                    children: [
                      TextSpan(
                        text: record.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' $summary',
                        style: const TextStyle(
                          color: AppColors.accent700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.date,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted55),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: loc.editButton,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.edit_outlined, size: 16),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: loc.deleteButton,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.delete_outline, size: 16),
          ),
        ],
      ),
    );
  }
}
